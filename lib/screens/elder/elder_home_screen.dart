import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';
import 'package:family_bridge/routes/app_routes.dart';
import 'package:family_bridge/utils/helpers.dart';
import 'package:family_bridge/widgets/elder/elder_action_button.dart';

class ElderHomeScreen extends StatelessWidget {
  const ElderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.elderBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Helpers.getGreeting(),
                style: TextStyle(
                  fontSize: AppConfig.elderHeaderFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.elderPrimaryColor,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                Helpers.formatDate(DateTime.now(), format: 'EEEE, MMMM dd, yyyy'),
                style: TextStyle(
                  fontSize: AppConfig.elderMinimumFontSize,
                  color: Colors.grey[700],
                ),
              ),
              
              const SizedBox(height: 48),
              
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1,
                  children: [
                    ElderActionButton(
                      icon: Icons.check_circle,
                      label: "I'm OK Today",
                      color: AppConfig.elderPrimaryColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.elderDailyCheckin);
                      },
                    ),
                    
                    ElderActionButton(
                      icon: Icons.phone,
                      label: 'Call for Help',
                      color: AppConfig.errorColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.elderEmergencyContacts);
                      },
                    ),
                    
                    ElderActionButton(
                      icon: Icons.medical_services,
                      label: 'My Medications',
                      color: AppConfig.primaryColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.elderMedication);
                      },
                    ),
                    
                    ElderActionButton(
                      icon: Icons.message,
                      label: 'Family Messages',
                      color: AppConfig.youthPrimaryColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.familyChat);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                width: double.infinity,
                height: AppConfig.elderMinimumTouchTarget,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic,
                          size: 32,
                          color: AppConfig.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tap to Speak',
                          style: TextStyle(
                            fontSize: AppConfig.elderButtonFontSize,
                            fontWeight: FontWeight.bold,
                            color: AppConfig.primaryColor,
                          ),
                        ),
                      ],
                    ),
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
