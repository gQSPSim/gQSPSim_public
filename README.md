# gQSPSim
## Description
gQSPSim is a GUI-based MATLAB® application that performs key steps in QSP model development and analyses, including:

1) model calibration using global and local optimization methods 
2) development of virtual subjects to explore variability and uncertainty in the represented biology 
3) simulations of virtual populations for different interventions.

gQSPSim works with SimBiology®-built models, utilizing components such as species, doses, variants, and rules. All functionalities are equipped with an interactive visualization interface and the ability to generate presentation-ready figures. In addition, standardized gQSPSim sessions can be shared or saved for future extension and reuse.

The source code and case studies are included in the referenced github account. The description of gQSPSim and case studies are in the publication titled "gQSPSim: a GUI application based on SimBiology® for standardized QSP model development and application".
## Release Procedure
We use a separate [repository](https://github.com/gQSPSim/gQSPsim-release/releases) to make releases of gQSPSim. 
While the source code is open to anybody for download, we strip the file histories prior to releases.
Release procedure:
1. In a development sandbox (aka repo), get a branch for the new release up-to-date, e.g. 
```
git pull origin v1.1_candidate
``` 
where origin is the development repo (e.g. git@github.com:gQSPSim/gQSPSim.git) and v1.1_candidate has the latest code for the release version.
2. Add the release repo as a remote (if not already):
```
git remote add release git@github.com:gQSPSim/gQSPsim-release.git
```
3. Push the release candidate branch to the release remote. 
```
git push remote v1.1_candidate
```
4. cd into your local copy of the release repo and pull the new branch pushed in the previous step. Note that "origin" in this case is the release repo.
```
git pull origin v1.1_candidate
git checkout v1.1_candidate
```
5. Because we don't want to share source code with file histories and because the new v1.1_candidate branch may be historically unrelated to the master branch we need:
```
git merge -s ours --allow-unrelated-histories master
```
This is merging master into our v1.1_candidate but NOT altering v1.1_candidate in any way. You can check this by diff'ing your local v1.1_candidate with the remote v1.1_candidate. 

6. It is then possible to request a pull into master from the new v1.1_candidate and delete v1.1_candidate.
7. Generate a mlappinstall using gQSPSim.prj in MATLAB (NOTE: I (pax) will try to automate this step asap).
8. Generate a mltbx using gQSPSimTLBX.prj in MATLAB (NOTE: I (pax) will try to automate this step asap).
9. Update the FEX entry to point to the new release. 
10. Add release notes and update other release information in the FEX entry page.
