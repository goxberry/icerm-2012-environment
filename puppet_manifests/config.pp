# Puppet manifest to provision a virtual machine for "Turnkey Reproducibility"
# presentation at ICERM 2012: Reproducibility in Experimental and
# Computational Mathematics.
# IMPORTANT NOTE: Puppet is a DECLARATIVE domain-specific language,
# so the order of the declaration of resources (file, apt::source, etc.)
# is immaterial; the order of execution only respects explicit
# dependencies (using the require, before, after, ->, <-, etc.)
# directives. See documentation for Puppet and the book "Pro Puppet"
# for full details of the Puppet language.

# TODO(goxberry@gmail.com): Write a script that pulls this setup from a
# Git repo of mine, then runs "vagrant up" and "vagrant provision".
# Make it a bash script, and tell Windows users to run it from the
# Git Bash shell.

group { "puppet":
        ensure => "present",
    }

# This file needed for package repository updates.
file { '/etc/apt/sources.list':
  ensure => present,
  }

# This file needed to modify sources list via apt::ppa and apt::source
file { '/etc/apt/sources.list.d':
  ensure => present,
  }

# Include the Precise Pangolin Ubuntu 12.04 LTS sources list,
# and make it a high priority so that it is the default
# sources list.
apt::source { 'precise':
  location          => "http://us.archive.ubuntu.com/ubuntu/",
  release           => "precise",
  repos             => "main restricted universe multiverse",
  pin               => "900",
  include_src       => true,
  require           => [ File['/etc/apt/sources.list.d'],
                         File['/etc/apt/sources.list'] ],
}

# Ensure that virtual machine gets the latest operating system
# updates first.
# Taken from:
# http://stackoverflow.com/questions/10845864/puppet-trick-run-apt-get-update-before-installing-other-packages
exec { 'apt-get update':
  command => '/usr/bin/apt-get update',
  require => [ File['/etc/apt/sources.list'],
               File['/etc/apt/sources.list.d'] ],
  }

# Install basic packages needed for a machine with a graphical interface.
# Inspired by http://escience.washington.edu/get-help-now/create-virtual-machine-software-bundling-or-reproducible-research
# Added BLAS and LAPACK packages for scipy, pip to pull in Python packages.
# Remaining packages are personal preference.
apt::force { ['xorg', 'xfce4', 'xfce4-terminal', 'xfce4-clipman', 'firefox',
 'gdm', 'build-essential', 'g++', 'python', 'scons', 'libboost-all-dev',
 'subversion', 'python-dev', 'ipython', 'ipython-notebook',
 'ipython-qtconsole', 'git', 'emacs', 'vim', 'git-svn', 'gfortran',
  'python-pip', 'libblas-dev',  'liblapack-dev', 'puppet',
   'cython', 'python-nose', 'python-pudb', 'python-matplotlib' ] :
  release => 'precise',
  require => Apt::Source['precise']
  }

# Install latest stable NumPy
package {'numpy':
  ensure => latest,
  provider => pip,
  require => Apt::Force['python-pip']
  }

# Install latest stable SciPy
package {'scipy':
  ensure => latest,
  provider => pip,
  require => [ Apt::Force['python-pip'],
               Apt::Force['build-essential'],
               Apt::Force['gfortran'],
               Apt::Force['libblas-dev'],
               Apt::Force['liblapack-dev'],
               Apt::Force['python-nose'],
               Apt::Force['cython'],
               Package['numpy'] ]
  }

# Python interface to Linda Petzold's DAE solver DASSL 
vcsrepo { '/usr/local/PyDAS' :
  ensure   => present,
  provider => git,
  source   => 'https://github.com/jwallen/PyDAS.git',
  revision => 'HEAD',
  require  => [ Apt::Force['git'],
                Package['numpy'],
                Package['scipy'],
                Apt::Force['cython'],
                Apt::Force['gfortran'] ]
  }

# Command to build cleanly PyDAS, which does not have the infrastructure
# to use pip.
exec {'make-PyDAS' :
  cwd => '/usr/local/PyDAS',
  command => '/usr/bin/make clean && \
  /usr/bin/python setup.py clean --all && \
  /usr/bin/make F77=/usr/bin/gfortran && \
  /usr/bin/python setup.py install',
  require => Vcsrepo['/usr/local/PyDAS'],
  }

# Download the ICERM 2012 Reproducibility Workshop example
# into the user home directory
vcsrepo { '/home/vagrant/icerm-example' :
  ensure => present,
  provider => git,
  source => 'https://github.com/goxberry/icerm-2012-environment.git',
  revison => 'HEAD',
  require => [ Apt::Force['git'],
               Package['numpy'],
               Package['scipy'],
               Vcsrepo['/usr/local/PyDAS'],
               Exec['make-PyDAS'] ]
  }
