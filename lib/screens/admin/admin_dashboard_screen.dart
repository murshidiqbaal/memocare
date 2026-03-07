import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 64,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'System Administration',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage users, requests, and system health',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildAdminCard(
                    context,
                    Icons.people_outline_rounded,
                    'Users',
                    Colors.blue,
                    null,
                  ),
                  _buildAdminCard(
                    context,
                    Icons.person_add_outlined,
                    'Caregiver Requests',
                    Colors.teal,
                    '/admin/caregiver-requests',
                  ),
                  _buildAdminCard(
                    context,
                    Icons.analytics_outlined,
                    'Analytics',
                    Colors.purple,
                    null,
                  ),
                  _buildAdminCard(
                    context,
                    Icons.bug_report_outlined,
                    'Logs',
                    Colors.orange,
                    null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, IconData icon, String label,
      Color color, String? route) {
    return InkWell(
      onTap: route != null ? () => context.push(route) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 165,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
