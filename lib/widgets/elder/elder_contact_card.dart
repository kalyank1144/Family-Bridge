import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';

class ElderContactCard extends StatelessWidget {
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? imageUrl;
  final VoidCallback onCall;

  const ElderContactCard({
    super.key,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.imageUrl,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppConfig.elderPrimaryColor,
            child: imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: AppConfig.elderButtonFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: AppConfig.elderButtonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relationship,
                  style: TextStyle(
                    fontSize: AppConfig.elderMinimumFontSize,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: AppConfig.elderMinimumFontSize,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          SizedBox(
            width: AppConfig.elderMinimumTouchTarget,
            height: AppConfig.elderMinimumTouchTarget,
            child: ElevatedButton(
              onPressed: onCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.elderPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(
                Icons.phone,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
