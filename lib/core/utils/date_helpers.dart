// 💡 날짜를 'YYYY-MM-DD' 문자열로 변환하는 유틸 함수
String dateToYMD(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
