# Appending to Perl's @INC array
#
# The @INC array is a list of directories Perl searches when attempting to
# load modules. To display the current contents of the @INC array:
#
# perl -e "print join(\"\n\", @INC);"
#
# The following two methods may be used to append to Perl's @INC array:
#
# 1. Add the directory to the PERL5LIB environment variable.
# 2. Add use lib 'directory'; in your Perl script.
#
# For more information, read the perlrun manpage or type perldoc lib.
#
# refer to  http://docstore.mik.ua/orelly/perl3/prog/ch31_13.htm

package QChemConst;
use strict;
use warnings;

use constant PI    => 4 * atan2(1, 1);

# Useful Physical Constants
use constant BOHR_RADIUS_IN_M          => 5.291772108e-11;
use constant ELECTRON_MASS_IN_KG       => 9.1093826e-31;
use constant ELECTRON_MASS_IN_AMU      => 5.4857990945e-04;
use constant ELECTRON_CHARGE_IN_C      => 1.60217653e-19;
use constant AVOGADRO_NUMBER           => 6.0221415e+23;
use constant PLANCK_CONSTANT_IN_J_HZ   => 6.6260693e-34;
use constant SPEED_OF_LIGHT_IN_M_S     => 2.99792458e+08;
use constant PERMITTIVITY_IN_F_M       => 8.854187817e-12;
use constant ONE_MOLE                  => 6.0221415e+23;
use constant JOULES_PER_CALORIE        => 4.184;
use constant BOLTZMANN_CONSTANT_IN_J_K => 1.3806505e-23;

# Derived Quantities
use constant BOHRS_TO_ANGSTROMS => BOHR_RADIUS_IN_M * 1.0e10;
use constant HARTREES_TO_JOULES => 0.25*ELECTRON_MASS_IN_KG*((ELECTRON_CHARGE_IN_C**2)/(PERMITTIVITY_IN_F_M*PLANCK_CONSTANT_IN_J_HZ))**2;
use constant HARTREES_TO_EV     => ELECTRON_CHARGE_IN_C/(BOHR_RADIUS_IN_M * 4.0e0 * PI * PERMITTIVITY_IN_F_M);
use constant HARTREES_TO_WAVENUMBERS => HARTREES_TO_JOULES / ( PLANCK_CONSTANT_IN_J_HZ * 100.0*SPEED_OF_LIGHT_IN_M_S );
use constant AU_TIME_IN_SEC	=> 2.0e0 * PLANCK_CONSTANT_IN_J_HZ * PERMITTIVITY_IN_F_M * BOHR_RADIUS_IN_M / (ELECTRON_CHARGE_IN_C**2);
use constant EV_TO_WAVENUMBERS	=> HARTREES_TO_WAVENUMBERS / HARTREES_TO_EV;


#############################
# Periodic Table
#############################
use vars qw(@ELEMENTS %ELEMENTS);
# our (@ELEMENTS,%ELEMENTS); % after perl 5.6
### Elements
@ELEMENTS = qw(
   n
   H                                                                   He
   Li  Be                                          B   C   N   O   F   Ne
   Na  Mg                                          Al  Si  P   S   Cl  Ar
   K   Ca  Sc  Ti  V   Cr  Mn  Fe  Co  Ni  Cu  Zn  Ga  Ge  As  Se  Br  Kr
   Rb  Sr  Y   Zr  Nb  Mo  Tc  Ru  Rh  Pd  Ag  Cd  In  Sn  Sb  Te  I   Xe
   Cs  Ba
       La  Ce  Pr  Nd  Pm  Sm  Eu  Gd  Tb  Dy  Ho  Er  Tm  Yb
           Lu  Hf  Ta  W   Re  Os  Ir  Pt  Au  Hg  Tl  Pb  Bi  Po  At  Rn
   Fr  Ra
       Ac  Th  Pa  U   Np  Pu  Am  Cm  Bk  Cf  Es  Fm  Md  No
           Lr  Rf  Db  Sg  Bh  Hs  Mt  Ds  Uuu Uub Uut Uuq Uup Uuh Uus Uuo
);

for (my $i=1; $i<@ELEMENTS; ++$i)
{
    $ELEMENTS{$ELEMENTS[$i]} = $i;
}

$ELEMENTS{D} = $ELEMENTS{T} = 1;

### Atomic Mass
our (@AMASS);
@AMASS = qw(
       0
       1.00783   4.00260   7.01600   9.01218  11.00931
      12.00000  14.00307  15.99491  18.99840  19.99244
      22.9898   23.98504  26.98153  27.97693  30.97376
      31.97207  34.96885  39.948    38.96371  39.96259
      44.95592  47.90     50.9440   51.9405   54.9380
      55.9349   58.9332   57.9353   62.9296   63.9291
      68.9257   73.9219   74.9216   79.9165   78.9183
      83.80     84.9117   87.9056   88.9059   89.9043
      92.9060   97.9055   98.9062  101.9037  102.9048
     105.9032  106.90509 113.9036  114.9041  118.69
     120.9038  129.9067  126.9044  131.9042  132.9051
     137.9050  138.9061  139.9053  140.9074  141.9075
     144.913   151.9195  152.9209  157.9241  159.9250
     163.9288  164.9303  165.9304  168.9344  173.9390
     174.9409  179.9468  180.9480  183.9510  186.9560
     192.      192.9633  194.9648  196.9666  201.9706
     204.9745  207.9766  208.9804  208.9825  209.987
     222.0175  223.0198  226.0254  227.0278  232.0382
     231.0359  238.0508  237.0480  244.064   243.0614
     247.070   247.0702  251.080   254.0881  257.095
);

1;	# return true value
