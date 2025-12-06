enum SortOption {
  updatedDesc,
  updatedAsc,
  createdDesc,
  createdAsc,
  titleAsc,
  titleDesc,
  colorAsc,
  colorDesc,
  sizeDesc,
  sizeAsc,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.updatedDesc:
        return 'Last Updated (Newest)';
      case SortOption.updatedAsc:
        return 'Last Updated (Oldest)';
      case SortOption.createdDesc:
        return 'Date Created (Newest)';
      case SortOption.createdAsc:
        return 'Date Created (Oldest)';
      case SortOption.titleAsc:
        return 'Title (A-Z)';
      case SortOption.titleDesc:
        return 'Title (Z-A)';
      case SortOption.colorAsc:
        return 'Color (Light to Dark)';
      case SortOption.colorDesc:
        return 'Color (Dark to Light)';
      case SortOption.sizeDesc:
        return 'Size (Largest)';
      case SortOption.sizeAsc:
        return 'Size (Smallest)';
    }
  }

  String get key {
    return toString().split('.').last;
  }
}
