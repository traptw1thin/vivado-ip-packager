# vivado-ip-packager

Creating a way to keep old IP versions without archiving that also keeps all the tooltips, names, etc that you likely don't want to have to redo every time

### Requirements

- Tested with: 
    - Vivado 2023.1 

    - Locally installed (separate from the tclsh included with Vivado) tclsh and tk/wish 8.5.19

    -   ```bash
        $ lsb_release -a
        LSB Version:	core-11.1.0ubuntu4-noarch:printing-11.1.0ubuntu4-noarch:security-11.1.0ubuntu4-noarch
        Distributor ID:	Ubuntu
        Description:	Ubuntu 22.04.4 LTS
        Release:	22.04
        Codename:	jammy
        ```

- Git

- An installed tcl and tk/wish that is version 8.5

### Installation

- Install tcl and tk/wish version 8.5

- Copy the `Scripts` directory to a known location on your machine

- Install tk_tunnel from the Vivado Store:
    - Tools > Vivado Store...
    - Search for `Tk Tunnel`
    - Click Install

### Workflow

1. For the first time you package a project as an IP just use the regular workflow, summarized here:
    1. Tools > Create and Package New IP...
    2. Go through the rest of the standard IP packaging process

2. When you want to package an updated version is when this project is useful

3. Run `source <parent directory of ip_packager.tcl>/ip_packager.tcl` in the Vivado Tcl Console

4. Follow prompts until the tk_tunnel instance closes and then continue the process to configure the IP in the Vivado IP Packager

### Notes

The file in the `Dev_Files` directory is nearly the same as the one in the scripts directory (at this time), except that it has a lot of my notes of things that didn't work and why. This is included solely for my own tracking in case any of that is ever useful, if you find it useful feel free to utilize it but the script inside the Scripts directory is the working (to the best of my ability) version