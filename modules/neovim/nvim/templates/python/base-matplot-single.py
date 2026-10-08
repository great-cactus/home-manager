import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

plt.style.use('cudo-paper')

fig, ax = plt.subplots()


{{_cursor_}}

ax.set_xlabel('x')
ax.set_ylabel('y')

for ext in ('png', 'pdf', 'svg'):
    fig.savefig(f'Fig_{{_name_}}_original.{ext}')
plt.show()
