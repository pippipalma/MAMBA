<img src="MAMBA.png" align="left" alt="drawing" width="140"/>

# MAMBA

Welcome to MAMBA, the computational cookbot for Multi-pAradigM voxel-Based Analysis.

<br />

The <a href="https://mathworks.com/products/matlab.html" target="_blank">Matlab</a> toolbox MAMBA is designed for the flexible application of statistical voxel-based (VB) analysis in different scenarios in medical imaging and radiation oncology. It provides open-source functions to compute VB statistical models of the input data, according to a great variety of regression schemes, and to derive VB maps of the observed significance level, performing a non-parametric permutation inference. The toolbox allows for including VB and global outcomes, as well as an arbitrary amount of VB and global explanatory variables. In addition, the Matlab <a href="https://mathworks.com/products/parallel-computing.html" target="_blank">Parallel Computing Toolbox</a> is exploited to take advantage of the perfect parallelizability of most workloads.

MAMBA is an open-source toolbox, freely available for academic and non-commercial purposes. It is designed to make state-of-the-art VB analysis accessible to research scientists without the programming resources needed to build from scratch their own software solutions. At the same time, the source code is handed out for more experienced users to complement their own tools, also customizing user-defined models.

Users are encouraged to freely adapt MAMBA according to their needs, and assume all responsibility and risk with respect to their use of the toolbox, which is provided “AS IS”. In addition, users are welcome to cite the following references, anywhere they use MAMBA:

- G. Palma, S. Monti, and L. Cella. <a href="https://www.sciencedirect.com/science/article/pii/S1120179719305344" target="_blank">*Voxel-based analysis in radiation oncology: A methodological cookbook*</a>. Physica Medica, 69:192–204, 2020;
- G. Palma, L. Cella, and S. Monti. <a href="https://aapm.onlinelibrary.wiley.com/doi/full/10.1002/mp.16260" target="_blank">*MAMBA—Multi-pAradigM voxel-Based Analysis: A computational cookbot*</a>. Medical Physics, 50:2317–2322, 2023.

The MAMBA User Manual (which includes the extensive reference manual and several examples that the user can fully work out on a synthetic dataset, as well as the toolbox configurations that led to clinical results previously published in the literature) can be found [here](Docs/UserManual.pdf).

## Getting started

To install MAMBA and run a quick example:

1. Download the latest version of MAMBA from [here](https://github.com/pippipalma/MAMBA/archive/refs/heads/main.zip);
2. Extract the content of ``MAMBA-main.zip`` to a ``folder/`` of your choice;
3. Open a Matlab session;
4. Add the following folders to the path of Matlab:
- ``folder/``;
- ``folder/Engine/``;
- ``folder/External/`` and its subfolders;
5. Change the Matlab current folder to ``folder/WorkedExamples/``;
6. Build a synthetic cohort with the function ``synthetic_cohort``;
7. Have fun with the available tests (*e.g.*, ``test2``).
