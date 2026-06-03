import 'package:flutter/material.dart';

const postSorts = ['hot', 'new', 'top', 'rising', 'controversial'];
const sortIcons = {
  'hot': Icons.local_fire_department_rounded,
  'new': Icons.fiber_new_rounded,
  'top': Icons.trending_up_rounded,
  'rising': Icons.show_chart_rounded,
  'controversial': Icons.swap_vert_rounded,
};
const sortLabels = {
  'hot': 'Hot',
  'new': 'New',
  'top': 'Top',
  'rising': 'Rising',
  'controversial': 'Controversial',
};
const timeFilters = ['all', 'hour', 'day', 'week', 'month', 'year'];
const timeFilterLabels = {
  'all': 'All time',
  'hour': 'Past hour',
  'day': 'Today',
  'week': 'This week',
  'month': 'This month',
  'year': 'This year',
};
const timeFilterSorts = {'top', 'controversial'};
const postTypes = <String?>{null, 'TEXT', 'IMAGE', 'VIDEO', 'LINK', 'POLL'};
const postTypeLabels = {
  null: 'All',
  'TEXT': 'Text',
  'IMAGE': 'Images',
  'VIDEO': 'Video',
  'LINK': 'Links',
  'POLL': 'Polls',
};
const postTypeIcons = {
  null: Icons.all_inclusive_rounded,
  'TEXT': Icons.article_outlined,
  'IMAGE': Icons.image_outlined,
  'VIDEO': Icons.videocam_outlined,
  'LINK': Icons.link_rounded,
  'POLL': Icons.poll_outlined,
};
