class DataList {
  final List<Data> dataList;

  DataList({this.dataList});

  factory DataList.fromJson(List<dynamic> parsedJson) {
    List<Data> data = List<Data>();
    data = parsedJson.map((i) => Data.fromJson(i)).toList();

    return DataList(dataList: data);
  }
}

class Data {
  int id, userId;
  String measurementLocation1,
      measurementLocation2,
      measurementLocation3,
      measurementLocation4,
      updatedTime,
      updatedDate;

  Data({
    this.id,
    this.measurementLocation1,
    this.measurementLocation2,
    this.measurementLocation3,
    this.measurementLocation4,
    this.updatedDate,
    this.updatedTime,
    this.userId,
  });

  factory Data.fromJson(Map<String, dynamic> parsedJson) {
    return Data(
        id: parsedJson['Id'],
        measurementLocation1: parsedJson['MeasurementLocation1'],
        measurementLocation2: parsedJson['MeasurementLocation2'],
        measurementLocation3: parsedJson['MeasurementLocation3'],
        measurementLocation4: parsedJson['MeasurementLocation4'],
        updatedDate: parsedJson['UpdatedDate'],
        updatedTime: parsedJson['UpdatedTime'],
        userId: parsedJson['UserId']);
  }
}
