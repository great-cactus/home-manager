from base_idt import CT_IDT
import numpy as np
import shutil
from utilities import mkdir, print2txt
import matplotlib.pyplot as plt

if __name__ == '__main__':
    CSVOUT = 'IDT.csv'
    OUTDIR = 'results'
    mkdir(OUTDIR)

    mech_name = 'chem.yaml'
    IDT = CT_IDT(mech_name)

    fuelComp = 'H2: 1'
    Pu = 1e5  # Pa
    oxyComp = f'O2: {21./78.}, N2: 1'
    phi = 1.0         # equivalence ratio

    Tu_arr = np.linspace(800, 2000, 100)  # K

    with open(CSVOUT, 'w') as cw:
        cw.write('Tu(K),P(Pa),idt(s)\n')

    idt_arr = np.zeros_like(Tu_arr)
    for idx, Tu in enumerate(Tu_arr):
        IDT.setGasPhi(Tu, Pu, fuelComp, oxyComp, phi)
        IDT.calcIDT()
        idt = IDT.getIDT()
        idt_arr[idx] = idt

        shutil.copy(IDT.DATAOUT, f'{OUTDIR}/idt_P_{Pu:.6e}_T_{Tu:.6e}.csv')
        print2txt(f'Tu: {Tu:.1f} K, P: {Pu:.3e} Pa -> IDT: {idt:.3e} sec')

        with open(CSVOUT, 'a') as ca:
            ca.write(f'{Tu:.1f},{Pu:.6e},{idt:.6e}\n')

    width = 90 / 25.4
    fig, ax = plt.subplots(1, 1, figsize=(width, width * 0.75))
    ax.plot(1000. / Tu_arr, idt_arr, color='black', marker='o')

    ax.set_yscale('log')

    ax.set_ylabel('ignition delay time (sec)')
    ax.set_xlabel(' 1000/Tu (1/K)')

    plt.tight_layout()
    plt.savefig('idt.png', dpi=300)
    plt.show()
