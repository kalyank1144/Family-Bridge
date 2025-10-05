import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';
import 'package:family_bridge/widgets/elder/elder_medication_card.dart';

class ElderMedicationScreen extends StatelessWidget {
  const ElderMedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.elderBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'My Medications',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Medications',
                style: TextStyle(
                  fontSize: AppConfig.elderButtonFontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryColor,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Expanded(
                child: ListView(
                  children: [
                    ElderMedicationCard(
                      medicationName: 'Aspirin',
                      dosage: '81mg',
                      time: '8:00 AM',
                      taken: true,
                      onTakeMedication: () {
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ElderMedicationCard(
                      medicationName: 'Lisinopril',
                      dosage: '10mg',
                      time: '12:00 PM',
                      taken: false,
                      onTakeMedication: () {
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ElderMedicationCard(
                      medicationName: 'Metformin',
                      dosage: '500mg',
                      time: '6:00 PM',
                      taken: false,
                      onTakeMedication: () {
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
