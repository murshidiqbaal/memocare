// import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// const corsHeaders = {
//     'Access-Control-Allow-Origin': '*',
//     'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
// }

// serve(async (req) => {
//     // Handle CORS preflight
//     if (req.method === 'OPTIONS') {
//         return new Response('ok', { headers: corsHeaders })
//     }

//     try {
//         const supabaseClient = createClient(
//             Deno.env.get('SUPABASE_URL') ?? '',
//             Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
//             { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
//         )

//         // Get user from token to ensure they are the patient
//         const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
//         if (authError || !user) throw new Error('Unauthorized')

//         const { patient_id, latitude, longitude, radius } = await req.json()

//         // Validate that patient_id matches user.id
//         if (patient_id !== user.id) {
//             throw new Error('You can only submit requests for yourself')
//         }

//         // Insert request record
//         const { data, error } = await supabaseClient
//             .from('location_change_requests')
//             .insert({
//                 patient_id: patient_id,
//                 requested_latitude: latitude,
//                 requested_longitude: longitude,
//                 requested_radius_meters: radius,
//                 status: 'pending'
//             })
//             .select()
//             .single()

//         if (error) throw error

//         return new Response(
//             JSON.stringify({ success: true, data }),
//             {
//                 headers: { ...corsHeaders, 'Content-Type': 'application/json' },
//                 status: 200
//             }
//         )

//     } catch (error) {
//         return new Response(
//             JSON.stringify({ error: error.message }),
//             {
//                 headers: { ...corsHeaders, 'Content-Type': 'application/json' },
//                 status: 400
//             }
//         )
//     }
// })
