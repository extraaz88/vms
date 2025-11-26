import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../core/providers/visit_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/visit_model.dart';
import '../../services/geocoding_service.dart';
import '../../widgets/app_logo.dart';
import '../../utils/responsive_utils.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().loadVisits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            AppLogo(
              width: ResponsiveUtils.getResponsiveIconSize(context, 24),
              height: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
            Text(
              'Visit History',
              style: TextStyle(fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: ResponsiveUtils.getResponsiveIconSize(context, 24)),
            onPressed: () {
              context.read<VisitProvider>().loadVisits();
            },
          ),
        ],
      ),
      body: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          if (visitProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (visitProvider.visits.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => visitProvider.loadVisits(),
            child: ListView.builder(
              padding: ResponsiveUtils.getResponsivePadding(context),
              itemCount: visitProvider.visits.length,
              itemBuilder: (context, index) {
                final visit = visitProvider.visits[index];
                return _buildVisitCard(visit, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: ResponsiveUtils.getResponsiveIconSize(context, 80),
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5),
          Text(
            'No Visits Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
          Text(
            'Your visit history will appear here',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/visit/checkin');
            },
            icon: Icon(Icons.add, size: ResponsiveUtils.getResponsiveIconSize(context, 20)),
            label: Text(
              'Start First Visit',
              style: TextStyle(fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(Visit visit, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getResponsiveSpacing(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, 16)),
          onTap: () => _showVisitDetails(visit),
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
                      decoration: BoxDecoration(
                        color: visit.isActive 
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, 8)),
                      ),
                      child: Icon(
                        visit.isActive ? Icons.location_on : Icons.check_circle,
                        color: visit.isActive 
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                        size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.clientName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22),
                            ),
                          ),
                          Text(
                            _formatDate(visit.visitTime),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                        vertical: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                      ),
                      decoration: BoxDecoration(
                        color: visit.isActive 
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, 12)),
                      ),
                      child: Text(
                        visit.isActive ? 'Active' : 'Completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: visit.isActive 
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                
                // Visit Details Form Data
                _buildVisitDetailsInfo(visit),
                
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                
                // Visit Time
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Visit Time',
                        _formatTime(visit.visitTime),
                        Icons.schedule,
                        AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
                    Expanded(
                      child: _buildDetailItem(
                        'Date',
                        _formatDate(visit.visitTime),
                        Icons.calendar_today,
                        AppTheme.secondaryColor,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
                    Expanded(
                      child: _buildDetailItem(
                        'Status',
                        visit.isActive ? 'Active' : 'Completed',
                        visit.isActive ? Icons.location_on : Icons.check_circle,
                        visit.isActive ? AppTheme.warningColor : AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                
                if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, 8)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: ResponsiveUtils.getResponsiveIconSize(context, 16),
                          color: AppTheme.textSecondaryColor,
                        ),
                        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
                        Expanded(
                          child: Text(
                            visit.notes!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
                
                // Location Info
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: ResponsiveUtils.getResponsiveIconSize(context, 16),
                      color: AppTheme.textSecondaryColor,
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
                    FutureBuilder<String>(
                      future: GeocodingService.getAreaName(visit.latitude, visit.longitude),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.textSecondaryColor,
                              ),
                            ),
                          );
                        }
                        
                        return Expanded(
                          child: Text(
                            snapshot.data ?? 'Location not available',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: (index * 100).ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildVisitDetailsInfo(Visit visit) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, 12)),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: ResponsiveUtils.getResponsiveIconSize(context, 16),
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
              Text(
                'Visit Details',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
          
          // Visiting Place
          if (visit.visitingReason != null && visit.visitingReason!.isNotEmpty)
            _buildInfoRow('Visiting Place', visit.visitingReason!),
          
          // Visiting Person (using notes field)
          if (visit.notes != null && visit.notes!.isNotEmpty)
            _buildInfoRow('Visiting Person', visit.notes!),
          
          // Visiting Area
          if (visit.visitingArea != null && visit.visitingArea!.isNotEmpty)
            _buildInfoRow('Visiting Area', visit.visitingArea!),
          
          // User
          _buildInfoRow('User', context.read<AuthProvider>().user?.name ?? 'User'),
          
          // Photo
          if (visit.photoPath != null && visit.photoPath!.isNotEmpty)
            _buildPhotoInfo(visit.photoPath!),
          
          // Location
          _buildLocationInfo(visit),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(Visit visit) {
    return Padding(
      padding: EdgeInsets.only(top: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Icon(
                Icons.location_on,
                size: ResponsiveUtils.getResponsiveIconSize(context, 16),
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
          Expanded(
            child: FutureBuilder<String>(
              future: GeocodingService.getAreaName(visit.latitude, visit.longitude),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
                      Text(
                        'Loading location...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  );
                }
                
                return Text(
                  snapshot.data ?? 'Location not available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoInfo(String photoPath) {
    // Build full image URL from filename
    final String imageUrl = _getImageUrl(photoPath);
    
    return Padding(
      padding: EdgeInsets.only(top: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                size: ResponsiveUtils.getResponsiveIconSize(context, 16),
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
              Text(
                'Visit Photo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(imageUrl, photoPath),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl, String photoPath) {
    // Debug print
    print('📸 Loading image: $photoPath');
    print('📸 Full URL: $imageUrl');
    
    // Check if it's a local file path or just filename
    if (photoPath.startsWith('/') || photoPath.contains('\\')) {
      // Local file path
      print('📸 Using local file');
      return Image.file(
        File(photoPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Local image error: $error');
          return _buildErrorPlaceholder();
        },
      );
    } else {
      // Network image from API
      print('📸 Using network URL');
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('✅ Image loaded successfully');
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Network image error: $error');
          print('❌ Tried URL: $imageUrl');
          return _buildErrorPlaceholder();
        },
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: ResponsiveUtils.getResponsiveIconSize(context, 50),
              color: Colors.grey,
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(String photoPath) {
    // If it's already a full URL, return as is
    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      return photoPath;
    }
    
    // If it's a local file path, return as is
    if (photoPath.startsWith('/') || photoPath.contains('\\')) {
      return photoPath;
    }
    
    // Otherwise, construct the full URL
    // Try different possible paths:
    // 1. https://live.extraaaz.com/storage/photos/
    // 2. https://live.extraaaz.com/photos/
    // 3. https://live.extraaaz.com/uploads/
    // 4. https://live.extraaaz.com/storage/app/public/photos/
    
    // Using the most common Laravel storage path
    return 'https://live.extraaaz.com/storage/photos/$photoPath';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getResponsiveSpacing(context) * 0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveUtils.getResponsiveIconSize(context, 16),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.125),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showVisitDetails(Visit visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVisitDetailsSheet(visit),
    );
  }

  Widget _buildVisitDetailsSheet(Visit visit) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Row(
              children: [
                Text(
                  'Visit Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 1.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Client Information', [
                    _buildDetailRow('Client Name', visit.clientName),
                    _buildDetailRow('Status', visit.isActive ? 'Active' : 'Completed'),
                  ]),
                  
                  _buildDetailSection('Visit Information', [
                    _buildDetailRow('Visit Date', _formatDate(visit.visitTime)),
                    _buildDetailRow('Visit Time', _formatTime(visit.visitTime)),
                    _buildDetailRow('Status', visit.isActive ? 'Active' : 'Completed'),
                  ]),
                  
                  _buildDetailSection('Location Information', [
                    _buildLocationDetailRow(visit),
                  ]),
                  
                  if (visit.notes != null && visit.notes!.isNotEmpty)
                    _buildDetailSection('Notes', [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          visit.notes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ]),
                  
                  
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 1.25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLocationDetailRow(Visit visit) {
    return FutureBuilder<String>(
      future: GeocodingService.getAreaName(visit.latitude, visit.longitude),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Location',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
                      Text(
                        'Loading location...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Location',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  snapshot.data ?? 'Location not available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

}
