roundDecimal(int unroundedSteps) {
  final lastNumber = unroundedSteps % 10;
  if (lastNumber == 0 || lastNumber == 5) {
    return unroundedSteps;
  } else if (lastNumber < 5) {
    return (unroundedSteps - lastNumber + 5);
  } else {
    return (unroundedSteps - lastNumber + 10);
  }
}
