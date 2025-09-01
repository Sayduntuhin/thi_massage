import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import '../../../controller/client_booking_list_conteroller.dart';
import '../widgets/booking_card.dart';

class ClientBookingsPage extends StatelessWidget {
  const ClientBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BookingsController controller = Get.put(BookingsController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Bookings", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500)),
        centerTitle: true,
      ),
      body: Obx(
            () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
          child: Container(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: ["All", "Completed", "Pending", "Upcoming", "Cancelled"].map((tab) {
                      bool isSelected = controller.selectedTab.value == tab;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: InkWell(
                          onTap: () {
                            controller.setSelectedTab(tab);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected ? boxColor : Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected ? borderColor.withAlpha(100) : Color(0xffE0E0E0),
                              ),
                            ),
                            child: Text(
                              tab,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: controller.filteredBookings.isEmpty
                      ? const Center(child: Text("No bookings found"))
                      : _buildBookingList(controller.filteredBookings),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 0.1.sw, right: 0.1.sw),
                  child: CustomGradientButton(
                    text: "Book an Appointment",
                    onPressed: () {
                      Get.toNamed('/appointmentPage');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList(List<Map<String, dynamic>> filteredBookings) {
    return ListView.builder(
      key: ValueKey(filteredBookings.hashCode),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        AppLogger.debug("Rendering booking ID: ${booking['id']}, Status: ${booking['status']}");
        return BookingCard(
          key: ValueKey(booking['id']),
          date: booking['date']!,
          year: booking['year']!,
          title: booking['title']!,
          therapist: booking['therapist']!,
          status: booking['status']!,
          time: booking['time']!,
          bookingId: booking['id'],
          therapistId: booking['therapist_id'],
          onBookingCancelled: Get.find<BookingsController>().fetchBookings,
          showReviewButton: booking['status'] == 'Completed',
          onReviewPressed: Get.find<BookingsController>().fetchBookings,
        );
      },
    );
  }
}