// // Supabase Edge Function: send-reminder-notification
// // Deploy with: supabase functions deploy send-reminder-notification

// import "jsr:@supabase/functions-js/edge-runtime.d.ts"


// // @ts-ignore - Ignore type declaration errors for the Deno/Supabase import in VS Code
// import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

// // ─────────────────────────────────────────────────────────────────────────────
// // Types
// // ─────────────────────────────────────────────────────────────────────────────

// interface NotificationPayload {
//   patient_id: string
//   reminder_id?: string
//   title: string
//   body: string
//   notification_type?: string
//   notify_patient?: boolean
//   notify_caregivers?: boolean
//   data?: Record<string, string>
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Main Handler
// // ─────────────────────────────────────────────────────────────────────────────

// Deno.serve(async (req: Request) => {
//   // CORS preflight
//   if (req.method === 'OPTIONS') {
//     return new Response('ok', {
//       headers: {
//         'Access-Control-Allow-Origin': '*',
//         'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
//       },
//     })
//   }

//   try {
//     let payload: NotificationPayload
//     try {
//       payload = await req.json()
//     } catch (e) {
//       console.error('[ERROR] Failed to parse JSON body', e)
//       return errorResponse('Invalid JSON payload', 400)
//     }

//     // ── Validate required fields ──────────────────────────────────────────────
//     if (!payload.patient_id || !payload.title || !payload.body) {
//       console.error('[ERROR] Missing required fields: patient_id, title, body')
//       return errorResponse('Missing required fields: patient_id, title, body', 400)
//     }

//     // ── Environment safety ────────────────────────────────────────────────────
//     const supabaseUrl = Deno.env.get('SUPABASE_URL')
//     const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
//     const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
//     const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')

//     if (!supabaseUrl || !supabaseKey) {
//       console.error('[ENV] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
//       return errorResponse('Internal Config Error: Missing Supabase Env Vars', 500)
//     }

//     if (!projectId || !serviceAccountJson) {
//       console.error('[ENV] Missing FIREBASE_PROJECT_ID or FIREBASE_SERVICE_ACCOUNT')
//       return errorResponse('Internal Config Error: Missing Firebase Env Vars', 500)
//     }

//     // ── Supabase Admin Client ─────────────────────────────────────────────────
//     const supabaseAdmin = createClient(supabaseUrl, supabaseKey, {
//       auth: { persistSession: false },
//     })

//     // ── Collect FCM tokens ────────────────────────────────────────────────────
//     const rawTokens: { token: string; role: string }[] = []

//     // 1. Patient token
//     if (payload.notify_patient !== false) {
//       const { data: patient, error: pErr } = await supabaseAdmin
//         .from('patients')
//         .select('fcm_token')
//         .eq('id', payload.patient_id)
//         .maybeSingle()

//       if (pErr) {
//         console.error('[ERROR] [DB] Error fetching patient token:', pErr.message)
//       } else if (patient?.fcm_token) {
//         rawTokens.push({ token: patient.fcm_token, role: 'patient' })
//       }
//     }

//     // 2. Linked caregiver tokens - Safe two-query join pattern
//     if (payload.notify_caregivers !== false) {
//       const { data: links, error: lErr } = await supabaseAdmin
//         .from('caregiver_patient_links')
//         .select('caregiver_id')
//         .eq('patient_id', payload.patient_id)

//       if (lErr) {
//         console.error('[ERROR] [DB] Error fetching caregiver links:', lErr.message)
//       } else if (links && links.length > 0) {
//         const caregiverIds = links.map((link: { caregiver_id: string }) => link.caregiver_id)
//         const { data: profiles, error: prErr } = await supabaseAdmin
//           .from('caregiver_profiles')
//           .select('id, fcm_token')
//           .in('id', caregiverIds)

//         if (prErr) {
//           console.error('[ERROR] [DB] Error fetching caregiver profiles:', prErr.message)
//         } else {
//           for (const profile of profiles ?? []) {
//             if (profile.fcm_token) {
//               rawTokens.push({ token: profile.fcm_token, role: 'caregiver' })
//             }
//           }
//         }
//       }
//     }

//     // ── Token Hygiene ─────────────────────────────────────────────────────────
//     const validTokens = new Map<string, string>() // deduplicate by token -> role
//     let skipped = 0

//     for (const t of rawTokens) {
//       if (!t.token) {
//         skipped++
//         continue
//       }
//       const trimmed = t.token.trim()
//       if (trimmed === '' || trimmed.toLowerCase() === 'null' || trimmed.toLowerCase() === 'undefined') {
//         skipped++
//         continue
//       }
//       if (!validTokens.has(trimmed)) {
//         validTokens.set(trimmed, t.role)
//       }
//     }

//     if (skipped > 0) {
//       console.log(`[TOKEN] Skipped ${skipped} empty, null, or malformed tokens.`)
//     }

//     const uniqueTokens = Array.from(validTokens.entries()).map(([token, role]) => ({ token, role }))

//     // Idempotency: Return success if no tokens to notify
//     if (uniqueTokens.length === 0) {
//       console.log('[FCM] No valid FCM tokens found for patient', payload.patient_id)
//       return successResponse({ sent: 0, failed: 0, total: 0, message: 'No FCM tokens available', reason: 'idempotent_no_tokens' })
//     }

//     // ── Get Firebase access token ─────────────────────────────────────────────
//     let accessToken: string
//     try {
//       accessToken = await getFirebaseAccessToken(serviceAccountJson)
//     } catch (authErr) {
//       console.error('[ERROR] [FCM] Firebase Auth failure:', String(authErr))
//       return errorResponse('Firebase Auth Error', 500)
//     }

//     // ── Send to each device safely ────────────────────────────────────────────
//     const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

//     console.log(`[FCM] Sending push notification to ${uniqueTokens.length} token(s)...`)

//     const results = await Promise.allSettled(
//       uniqueTokens.map(({ token, role }) =>
//         sendFCMMessage(fcmUrl, accessToken, {
//           token,
//           title: payload.title,
//           body: payload.body,
//           data: {
//             type: 'reminder',
//             reminder_id: payload.reminder_id ?? '',
//             notification_type: payload.notification_type ?? 'reminder_due',
//             patient_id: payload.patient_id,
//             role,
//             ...(payload.data ?? {}),
//           },
//         })
//       )
//     )

//     const sent = results.filter((r) => r.status === 'fulfilled').length
//     const failedRuns = results.filter((r) => r.status === 'rejected') as PromiseRejectedResult[]
//     const failed = failedRuns.length

//     failedRuns.forEach((result, idx) => {
//       console.error(`[ERROR] [FCM] Send failed for token batch index ${idx}:`, result.reason)
//     })

//     // ── Log to notification_log safely ────────────────────────────────────────
//     try {
//       const { error: logErr } = await supabaseAdmin.from('notification_log').insert({
//         patient_id: payload.patient_id,
//         notification_type: payload.notification_type ?? 'reminder_due',
//         title: payload.title,
//         body: payload.body,
//         data: payload.data ?? {},
//         sent_at: new Date().toISOString(),
//         delivered: sent > 0,
//         error: failed > 0 ? `${failed} of ${uniqueTokens.length} failed` : null,
//       })

//       if (logErr) {
//         console.error('[ERROR] [DB] Failed to insert into notification_log:', logErr.message)
//       }
//     } catch (logCrashErr) {
//       console.error('[ERROR] [DB] Exception while inserting notification_log:', String(logCrashErr))
//       // DO NOT THROW, function must complete successfully if send was attempted
//     }

//     console.log(`[FCM] Completed batch. Sent: ${sent}, Failed: ${failed}`)
//     return successResponse({ sent, failed, total: uniqueTokens.length })

//   } catch (err) {
//     console.error('[ERROR] Unhandled edge function exception:', err)
//     return errorResponse('Internal server error', 500)
//   }
// })

// // ─────────────────────────────────────────────────────────────────────────────
// // Send a single FCM message via HTTP v1 API with Timeout protection
// // ─────────────────────────────────────────────────────────────────────────────
// async function sendFCMMessage(
//   fcmUrl: string,
//   accessToken: string,
//   options: {
//     token: string
//     title: string
//     body: string
//     data: Record<string, string>
//   }
// ): Promise<void> {
//   const isEmergency = options.data.notification_type?.includes('sos') || options.data.notification_type?.includes('emergency')

//   const message = {
//     token: options.token,
//     notification: {
//       title: options.title,
//       body: options.body,
//     },
//     data: options.data,
//     android: {
//       priority: 'high',
//       notification: {
//         channel_id: isEmergency ? 'emergency_channel' : 'reminder_channel',
//         priority: 'PRIORITY_HIGH',
//         default_sound: true,
//         default_vibrate_timings: true,
//         notification_priority: 'PRIORITY_HIGH',
//       },
//     },
//   }

//   const controller = new AbortController()
//   const timeoutId = setTimeout(() => controller.abort(), 10000) // 10s individual timeout

//   try {
//     const response = await fetch(fcmUrl, {
//       method: 'POST',
//       headers: {
//         'Authorization': `Bearer ${accessToken}`,
//         'Content-Type': 'application/json',
//       },
//       body: JSON.stringify({ message }),
//       signal: controller.signal,
//     })

//     if (!response.ok) {
//       let errorBody = 'No body returned'
//       try {
//         errorBody = await response.text()
//       } catch (e) {
//         // Ignore parsing body if it fails
//       }
//       throw new Error(`FCM HTTP ${response.status}: ${errorBody}`)
//     }

//     const result = await response.json()
//     console.log(`[FCM] Message delivered successfully: ${result.name}`)
//   } catch (err) {
//     if ((err as Error).name === 'AbortError') {
//       throw new Error('FCM request timed out after 10 seconds')
//     }
//     throw err
//   } finally {
//     clearTimeout(timeoutId)
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Get a short-lived Firebase OAuth2 access token via service account JWT
// // ─────────────────────────────────────────────────────────────────────────────
// async function getFirebaseAccessToken(serviceAccountJson: string): Promise<string> {
//   let serviceAccount
//   try {
//     serviceAccount = JSON.parse(serviceAccountJson)
//   } catch (err) {
//     console.error('[ENV] Invalid FIREBASE_SERVICE_ACCOUNT JSON: Failed to parse')
//     throw new Error('Invalid FIREBASE_SERVICE_ACCOUNT JSON: Failed to parse')
//   }

//   if (!serviceAccount.client_email || !serviceAccount.private_key) {
//     console.error('[ENV] Invalid FIREBASE_SERVICE_ACCOUNT: Missing fields')
//     throw new Error('FIREBASE_SERVICE_ACCOUNT missing client_email or private_key')
//   }

//   const now = Math.floor(Date.now() / 1000)
//   const expiresAt = now + 3600 // 1 hour

//   const header = { alg: 'RS256', typ: 'JWT' }
//   const payload = {
//     iss: serviceAccount.client_email,
//     sub: serviceAccount.client_email,
//     aud: 'https://oauth2.googleapis.com/token',
//     iat: now,
//     exp: expiresAt,
//     scope: 'https://www.googleapis.com/auth/firebase.messaging',
//   }

//   const encodeBase64Url = (obj: unknown) => {
//     const uint8 = new TextEncoder().encode(JSON.stringify(obj))
//     let str = ''
//     for (let i = 0; i < uint8.length; i++) {
//       str += String.fromCharCode(uint8[i])
//     }
//     return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
//   }

//   const signingInput = `${encodeBase64Url(header)}.${encodeBase64Url(payload)}`

//   // Import private key and handle potential crypto errors
//   let privateKey: CryptoKey
//   try {
//     privateKey = await importPrivateKey(serviceAccount.private_key)
//   } catch (err) {
//     console.error('[ENV] Crypto failure: Bad or malformed private key format.')
//     throw err
//   }

//   let signature: ArrayBuffer
//   try {
//     signature = await crypto.subtle.sign(
//       { name: 'RSASSA-PKCS1-v1_5' },
//       privateKey,
//       new TextEncoder().encode(signingInput)
//     )
//   } catch (err) {
//     console.error('[ERROR] Crypto signing failure:', err)
//     throw new Error('Failed to sign JWT with provided private key')
//   }

//   const signatureUint8 = new Uint8Array(signature)
//   let signatureStr = ''
//   for (let i = 0; i < signatureUint8.length; i++) {
//     signatureStr += String.fromCharCode(signatureUint8[i])
//   }

//   const signatureB64Url = btoa(signatureStr)
//     .replace(/\+/g, '-')
//     .replace(/\//g, '_')
//     .replace(/=+$/, '')

//   const jwt = `${signingInput}.${signatureB64Url}`

//   // Exchange JWT for OAuth2 access token
//   const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
//     method: 'POST',
//     headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
//     body: new URLSearchParams({
//       grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
//       assertion: jwt,
//     }),
//   })

//   if (!tokenResponse.ok) {
//     const errorBody = await tokenResponse.text()
//     console.error('[ERROR] [FCM] OAuth2 token exchange failed:', errorBody)
//     throw new Error(`OAuth2 token exchange failed: ${tokenResponse.status}`)
//   }

//   const tokenData = await tokenResponse.json()
//   return tokenData.access_token
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Import RSA private key from PEM string safely
// // ─────────────────────────────────────────────────────────────────────────────
// async function importPrivateKey(pem: string): Promise<CryptoKey> {
//   const pemHeader = '-----BEGIN PRIVATE KEY-----'
//   const pemFooter = '-----END PRIVATE KEY-----'

//   if (!pem.includes(pemHeader) || !pem.includes(pemFooter)) {
//     throw new Error('PEM string does not contain valid BEGIN/END tags')
//   }

//   const pemContents = pem
//     .substring(pem.indexOf(pemHeader) + pemHeader.length, pem.indexOf(pemFooter))
//     .replace(/\s/g, '') // Strips out spaces and new lines

//   const binaryDerString = atob(pemContents)
//   const binaryDer = new Uint8Array(binaryDerString.length)
//   for (let i = 0; i < binaryDerString.length; i++) {
//     binaryDer[i] = binaryDerString.charCodeAt(i)
//   }

//   return await crypto.subtle.importKey(
//     'pkcs8',
//     binaryDer.buffer,
//     { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
//     false,
//     ['sign']
//   )
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Response helpers
// // ─────────────────────────────────────────────────────────────────────────────

// function successResponse(data: unknown): Response {
//   return new Response(JSON.stringify(data), {
//     headers: { 'Content-Type': 'application/json' },
//     status: 200,
//   })
// }

// function errorResponse(message: string, status: number): Response {
//   return new Response(JSON.stringify({ error: message }), {
//     headers: { 'Content-Type': 'application/json' },
//     status,
//   })
// }
