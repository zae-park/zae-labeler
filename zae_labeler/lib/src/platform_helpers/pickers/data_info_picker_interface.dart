import 'package:zae_labeler/src/core/models/data/data_info.dart';

abstract class DataInfoPicker {
  Future<List<DataInfo>> pick();
}
