sub wrt_log {

use vars qw/$ModuleName $Facility/;

# ���W���[���̓ǂݍ���
use Sys::Syslog;

# ����
my $prog_name = $_[0];
my $priority = $_[1];
my $message = $_[2];
my $prio = uc $priority;

openlog($ModuleName, 'cons,pid', $Facility);

syslog($priority, "%s", "[$prio]:$prog_name:$message");

closelog();

}
1;
