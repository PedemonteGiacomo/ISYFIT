import 'package:flutter/material.dart';

class PTDashboard extends StatelessWidget {
  const PTDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IsyFit Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Overview Section
            _buildSectionTitle('Today’s Overview'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildListTile(
                      title: 'Upcoming Session: John Doe - 10:00 AM',
                      icon: Icons.schedule,
                    ),
                    _buildListTile(
                      title: 'Pending Client Requests: 2',
                      icon: Icons.group_add,
                    ),
                    _buildListTile(
                      title: 'Tasks: Finalize 3 Training Plans',
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Client Management Section
            _buildSectionTitle('Clients'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search Clients',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildListTile(
                      title: 'John Doe - Training Plan',
                      icon: Icons.person,
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(context, '/client-profile');
                      },
                    ),
                    _buildListTile(
                      title: 'Jane Smith - Medical History',
                      icon: Icons.person,
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(context, '/client-profile');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Training Plans Section
            _buildSectionTitle('Training Plans'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildListTile(
                      title: 'Create New Plan',
                      icon: Icons.add_circle,
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(context, '/create-training-plan');
                      },
                    ),
                    _buildListTile(
                      title: 'View All Plans',
                      icon: Icons.list,
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(context, '/training-plans');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Medical Records Section
            _buildSectionTitle('Medical Records'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildListTile(
                      title: 'Update Client Records',
                      icon: Icons.edit,
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(context, '/update-medical-records');
                      },
                    ),
                    _buildListTile(
                      title: 'View Medical Records',
                      icon: Icons.medical_services,
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pushNamed(context, '/medical-records');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 32),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
