import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationReminders = false;
  bool _emailUpdates = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    userProfile?.name?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      fontSize: 40,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userProfile?.name ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  userProfile?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Profile Information
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            subtitle: Text(userProfile?.name ?? 'Not set'),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('University'),
            subtitle: Text(userProfile?.university ?? 'Not set'),
          ),
          
          const Divider(),
          
          // Notification Settings
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notification Reminders'),
            subtitle: const Text('Get reminders about your swaps'),
            value: _notificationReminders,
            onChanged: (value) {
              setState(() {
                _notificationReminders = value;
              });
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Email Updates'),
            subtitle: const Text('Receive email notifications'),
            value: _emailUpdates,
            onChanged: (value) {
              setState(() {
                _emailUpdates = value;
              });
            },
          ),
          
          const Divider(),
          
          // Log Out Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await authProvider.signOut();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

