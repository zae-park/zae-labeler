// lib/src/platform_helpers/pickers/data_info_picker_interface.dart
import 'package:zae_labeler/src/core/models/data/data_info.dart';

abstract class DataInfoPicker {
  Future<List<DataInfo>> pick();
}
