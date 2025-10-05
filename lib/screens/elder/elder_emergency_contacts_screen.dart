import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';
import 'package:family_bridge/widgets/elder/elder_contact_card.dart';

class ElderEmergencyContactsScreen extends StatelessWidget {
  const ElderEmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.elderBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.elderPrimaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: AppConfig.elderButtonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    ElderContactCard(
                      name: 'John Smith',
                      relationship: 'Son',
                      phoneNumber: '+1 (555) 123-4567',
                      imageUrl: null,
                      onCall: () {
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    ElderContactCard(
                      name: 'Mary Johnson',
                      relationship: 'Daughter',
                      phoneNumber: '+1 (555) 987-6543',
                      imageUrl: null,
                      onCall: () {
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    ElderContactCard(
                      name: 'Dr. Williams',
                      relationship: 'Doctor',
                      phoneNumber: '+1 (555) 246-8135',
                      imageUrl: null,
                      onCall: () {
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: AppConfig.elderMinimumTouchTarget,
                child: ElevatedButton(
                  onPressed: () {
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.elderPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Contact',
                        style: TextStyle(
                          fontSize: AppConfig.elderButtonFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
