from base_lfs import CT_LFS
import cantera as ct
import numpy as np
import shutil
from utilities import mkdir, print2txt
import matplotlib.pyplot as plt

if __name__ == '__main__':
    CSVOUT = 'LFS.csv'
    OUTDIR = 'results'
    mkdir(OUTDIR)

    mech_name = 'chem.yaml'
    LFS = CT_LFS(mech_name)

    fuel_name = 'H2: 1'
    pressure = ct.one_atm  # Pa
    inert = 'N2'
    z_ratio = 21. / 78.  # z = [O2]/[Inert], z = 21/78 for Air
    Tu = 1000.  # K
    width = 0.1
    isRestart = False

    phi_arr = np.linspace(0.8, 1.2, 5)  # K

    with open(CSVOUT, 'w') as cw:
        cw.write('Tu(K),P(Pa),lfs(s)\n')

    lfs_arr = np.zeros_like(phi_arr)
    for idx, phi in enumerate(phi_arr):
        LFS.DATAOUT = f'{OUTDIR}/lfs_P_{pressure:.6e}_T_{Tu:.6e}.csv'
        LFS.setFlamePhi(width, Tu, pressure, fuel_name, f'O2: {z_ratio}, {inert}: 1.', phi)
        LFS.calcLFS(isRestart, 1/3)
        lfs = LFS.getLFS()
        lfs_arr[idx] = lfs

        print2txt(f'Tu: {Tu:.1f} K, P: {pressure:.3e} Pa -> LFS: {lfs:.3e} sec')

        with open(CSVOUT, 'a') as ca:
            ca.write(f'{Tu:.1f},{pressure:.6e},{lfs:.6e}\n')

    width = 90 / 25.4
    fig, ax = plt.subplots(1, 1, figsize=(width, width * 0.75))
    ax.plot(phi_arr, lfs_arr, color='black', marker='o')

    ax.set_yscale('log')

    ax.set_ylabel('laminar flame speed (m/s)')
    ax.set_xlabel('phi')

    plt.tight_layout()
    plt.savefig('lfs.png', dpi=300)
    plt.show()
