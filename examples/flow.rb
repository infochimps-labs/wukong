

source('something/web/logs') |
  from_apache_logs |
  project{|visit|
  ping(:dashboard, visit.duration)
  pint(:dashboard, visit.status)

}
