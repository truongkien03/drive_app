import 'package:flutter/material.dart';
import '../../utils/app_color.dart';
import '../../utils/dimension.dart';

class TripSharingScreen extends StatefulWidget {
  const TripSharingScreen({Key? key}) : super(key: key);

  @override
  State<TripSharingScreen> createState() => _TripSharingScreenState();
}

class _TripSharingScreenState extends State<TripSharingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _seatsController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  
  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _createTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã tạo chuyến đi thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Reset form
      _formKey.currentState!.reset();
      _fromController.clear();
      _toController.clear();
      _seatsController.clear();
      _priceController.clear();
      _dateController.clear();
      _timeController.clear();
      _selectedDate = null;
      _selectedTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Chia sẻ chuyến đi',
          style: TextStyle(
            fontSize: Dimension.font_size18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Dimension.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              padding: EdgeInsets.all(Dimension.width16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColor.primary, AppColor.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(Dimension.radius12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: Dimension.icon24,
                  ),
                  SizedBox(width: Dimension.width12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo chuyến đi mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Dimension.font_size18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: Dimension.height4),
                        Text(
                          'Chia sẻ chuyến đi và kiếm thêm thu nhập',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: Dimension.font_size14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: Dimension.height20),
            
            // Create trip form
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimension.radius12),
              ),
              child: Padding(
                padding: EdgeInsets.all(Dimension.width16),
                child: Form(
                  key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        'Thông tin chuyến đi',
                      style: TextStyle(
                          fontSize: Dimension.font_size16,
                        fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                      ),
                    ),
                      SizedBox(height: Dimension.height16),
                      
                      // From location
                      _buildTextField(
                        controller: _fromController,
                        label: 'Điểm đi',
                        icon: Icons.location_on,
                        iconColor: Colors.green,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập điểm đi';
                          }
                          return null;
                        },
                    ),
                      
                      SizedBox(height: Dimension.height12),
                      
                      // To location
                      _buildTextField(
                        controller: _toController,
                        label: 'Điểm đến',
                        icon: Icons.flag,
                        iconColor: Colors.red,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập điểm đến';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: Dimension.height12),
                      
                      // Date and Time row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _dateController,
                              label: 'Ngày đi',
                              icon: Icons.calendar_today,
                              iconColor: Colors.blue,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng chọn ngày';
                                }
                                return null;
                              },
                      ),
                    ),
                          SizedBox(width: Dimension.width12),
                          Expanded(
                            child: _buildTextField(
                              controller: _timeController,
                              label: 'Giờ đi',
                              icon: Icons.access_time,
                              iconColor: Colors.orange,
                              readOnly: true,
                              onTap: () => _selectTime(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng chọn giờ';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: Dimension.height12),
                      
                      // Seats and Price row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _seatsController,
                              label: 'Số ghế trống',
                              icon: Icons.airline_seat_recline_normal,
                              iconColor: Colors.purple,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập số ghế';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Vui lòng nhập số hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: Dimension.width12),
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'Giá/ghế (VNĐ)',
                              icon: Icons.money,
                              iconColor: Colors.green,
                      keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập giá';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Vui lòng nhập số hợp lệ';
                                }
                                return null;
                              },
                            ),
                      ),
                        ],
                      ),
                      
                      SizedBox(height: Dimension.height20),
                      
                      // Create button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createTrip,
                      style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: Dimension.height16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Dimension.radius12),
                            ),
                            elevation: 2,
                      ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: Dimension.icon20,
                                      height: Dimension.icon20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: Dimension.width8),
                                    Text(
                                      'Đang tạo...',
                                      style: TextStyle(fontSize: Dimension.font_size16),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: Dimension.icon20),
                                    SizedBox(width: Dimension.width8),
                                    Text(
                                      'Tạo chuyến đi',
                                      style: TextStyle(
                                        fontSize: Dimension.font_size16,
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
            ),
            
            SizedBox(height: Dimension.height20),
            
            // Existing trips section
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppColor.primary,
                  size: Dimension.icon20,
                ),
                SizedBox(width: Dimension.width8),
                Text(
              'Chuyến đi đã tạo',
                  style: TextStyle(
                    fontSize: Dimension.font_size18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: Dimension.height12),
            
            // Trip list
            _buildTripList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor, size: Dimension.icon20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimension.radius12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimension.radius12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimension.radius12),
          borderSide: BorderSide(color: AppColor.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimension.radius12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: Dimension.width12,
          vertical: Dimension.height12,
        ),
      ),
    );
  }

  Widget _buildTripList() {
    final trips = [
      {
        'id': '1',
        'from': 'Hà Nội',
        'to': 'Hải Phòng',
        'date': '15/12/2024',
        'time': '08:00',
        'seats': 3,
        'price': 150000,
        'status': 'active',
      },
      {
        'id': '2',
        'from': 'Hà Nội',
        'to': 'Nam Định',
        'date': '16/12/2024',
        'time': '14:30',
        'seats': 2,
        'price': 120000,
        'status': 'active',
      },
      {
        'id': '3',
        'from': 'Hà Nội',
        'to': 'Thái Bình',
        'date': '17/12/2024',
        'time': '09:15',
        'seats': 1,
        'price': 180000,
        'status': 'completed',
      },
    ];

    if (trips.isEmpty) {
      return Container(
        padding: EdgeInsets.all(Dimension.width20),
        child: Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: Dimension.icon24 * 2,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: Dimension.height12),
            Text(
              'Chưa có chuyến đi nào',
              style: TextStyle(
                fontSize: Dimension.font_size16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: Dimension.height8),
            Text(
              'Tạo chuyến đi đầu tiên để bắt đầu chia sẻ',
              style: TextStyle(
                fontSize: Dimension.font_size14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        final isCompleted = trip['status'] == 'completed';
        
        return Card(
          margin: EdgeInsets.only(bottom: Dimension.height8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimension.radius12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(Dimension.width12),
            leading: Container(
              width: Dimension.width50,
              height: Dimension.width50,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Colors.grey.shade300 
                    : AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimension.radius12),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.directions_car,
                color: isCompleted ? Colors.grey : AppColor.primary,
                size: Dimension.icon24,
              ),
            ),
            title: Text(
              '${trip['from']} - ${trip['to']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Dimension.font_size16,
                color: isCompleted ? Colors.grey : AppColor.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: Dimension.height4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: Dimension.icon16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: Dimension.width4),
                    Flexible(
                      child: Text(
                        '${trip['date']} ${trip['time']}',
                        style: TextStyle(
                          fontSize: Dimension.font_size14,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimension.height4),
                Row(
                  children: [
                    Icon(
                      Icons.airline_seat_recline_normal,
                      size: Dimension.icon16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: Dimension.width4),
                    Flexible(
                      child: Text(
                        'Còn ${trip['seats']} ghế trống',
                        style: TextStyle(
                          fontSize: Dimension.font_size14,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: Dimension.width8),
                    Icon(
                      Icons.money,
                      size: Dimension.icon16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: Dimension.width4),
                    Flexible(
                      child: Text(
                        '${trip['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} VNĐ',
                        style: TextStyle(
                          fontSize: Dimension.font_size14,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isCompleted
                ? Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimension.width8,
                      vertical: Dimension.height4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(Dimension.radius8),
                      ),
                    child: Text(
                      'Hoàn thành',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Dimension.font_size12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: AppColor.primary),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          // TODO: Edit trip
                          break;
                        case 'delete':
                          // TODO: Delete trip
                          break;
                        case 'share':
                          // TODO: Share trip
                          break;
                      }
                    },
                        itemBuilder: (context) => [
                      PopupMenuItem(
                            value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: Dimension.icon16),
                            SizedBox(width: Dimension.width8),
                            Text('Chỉnh sửa'),
                          ],
                          ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: Dimension.icon16),
                            SizedBox(width: Dimension.width8),
                            Text('Chia sẻ'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                            value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: Dimension.icon16, color: Colors.red),
                            SizedBox(width: Dimension.width8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}
