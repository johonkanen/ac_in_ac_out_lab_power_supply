start /wait pwsh write_git_hash.ps1
d:/Efinity/2024.2/bin/setup.bat & cd titanium_build & efx_run.bat --prj titanium_build.xml & d:/Efinity/2023.2/bin/setup.bat & efx_run.bat titanium_build.xml --flow program --pgm_opts mode=jtag ;
exit
