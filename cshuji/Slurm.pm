package cshuji::Slurm;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();
our @EXPORT = qw();

BEGIN {
    # for backward compatibility
    if (eval "use cshuji::Slurm::Local; 1") {
        cshuji::Slurm::Local->export_to_level(1, "cshuji::Slurm::Local", @cshuji::Slurm::Local::EXPORT);
    }
}

1;
