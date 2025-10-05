import 'package:flutter/material.dart';
import 'package:family_bridge/screens/common/welcome_screen.dart';
import 'package:family_bridge/screens/common/user_type_selection_screen.dart';
import 'package:family_bridge/screens/elder/elder_home_screen.dart';
import 'package:family_bridge/screens/elder/elder_emergency_contacts_screen.dart';
import 'package:family_bridge/screens/elder/elder_medication_screen.dart';
import 'package:family_bridge/screens/elder/elder_daily_checkin_screen.dart';
import 'package:family_bridge/screens/caregiver/caregiver_home_screen.dart';
import 'package:family_bridge/screens/caregiver/caregiver_health_monitoring_screen.dart';
import 'package:family_bridge/screens/caregiver/caregiver_appointments_screen.dart';
import 'package:family_bridge/screens/youth/youth_home_screen.dart';
import 'package:family_bridge/screens/youth/youth_story_time_screen.dart';
import 'package:family_bridge/screens/common/family_chat_screen.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String userTypeSelection = '/user-type-selection';
  
  static const String elderHome = '/elder/home';
  static const String elderEmergencyContacts = '/elder/emergency-contacts';
  static const String elderMedication = '/elder/medication';
  static const String elderDailyCheckin = '/elder/daily-checkin';
  
  static const String caregiverHome = '/caregiver/home';
  static const String caregiverHealthMonitoring = '/caregiver/health-monitoring';
  static const String caregiverAppointments = '/caregiver/appointments';
  
  static const String youthHome = '/youth/home';
  static const String youthStoryTime = '/youth/story-time';
  
  static const String familyChat = '/family-chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      
      case userTypeSelection:
        return MaterialPageRoute(builder: (_) => const UserTypeSelectionScreen());
      
      case elderHome:
        return MaterialPageRoute(builder: (_) => const ElderHomeScreen());
      
      case elderEmergencyContacts:
        return MaterialPageRoute(builder: (_) => const ElderEmergencyContactsScreen());
      
      case elderMedication:
        return MaterialPageRoute(builder: (_) => const ElderMedicationScreen());
      
      case elderDailyCheckin:
        return MaterialPageRoute(builder: (_) => const ElderDailyCheckinScreen());
      
      case caregiverHome:
        return MaterialPageRoute(builder: (_) => const CaregiverHomeScreen());
      
      case caregiverHealthMonitoring:
        return MaterialPageRoute(builder: (_) => const CaregiverHealthMonitoringScreen());
      
      case caregiverAppointments:
        return MaterialPageRoute(builder: (_) => const CaregiverAppointmentsScreen());
      
      case youthHome:
        return MaterialPageRoute(builder: (_) => const YouthHomeScreen());
      
      case youthStoryTime:
        return MaterialPageRoute(builder: (_) => const YouthStoryTimeScreen());
      
      case familyChat:
        return MaterialPageRoute(builder: (_) => const FamilyChatScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
