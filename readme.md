# ReSCom: Reconfigurable SNN Accelerator Using Stochastic Computing

This repository contains the hardware and software implementation of **ReSCom**, a reconfigurable Spiking Neural Network (SNN) accelerator that leverages stochastic computing for efficient inference on FPGA.

## 📄 Paper Reference

**Title:** ReSCom: A Reconfigurable Spiking Neural Network Accelerator Using Stochastic Computing  
**Authors:** Ali Alipour Fereidani, Mohammad Rasoul Roshanshah and Saeed Safari
**Published:** arXiv:2606.13560 (June 2026)  
**Link:** [https://arxiv.org/abs/2606.13560](https://arxiv.org/abs/2606.13560)

## 📁 Project Structure

```bash
├── HardwareImplementation
│   ├── A.StochasticComputing_FC_Share
│   ├── B.DSP_FC_Share
│   ├── C.Array_Multiplier_FC_Share
│   └── D.Shift_Registe_FC_Share
└── SoftwareImplemenetation
    ├── DVS_Dataset.ipynb
    ├── MNIST_Dataset.ipynb
    ├── requirements.txt
    ├── SHD_Dataset.ipynb
    └── stochastic_curves.ipynb

```

## 🧠 Key Features

- **Stochastic Computing:** Uses stochastic arithmetic for multiplications to reduce hardware complexity.
- **Reconfigurable Neuron Models:** Supports **Integrate-and-Fire (IF)**, **Leaky Integrate-and-Fire (LIF)**, and **Synaptic** neuron models.
- **Exact Fixed-Point Operations:** Preserves exact addition/subtraction for stable recurrent updates.
- **Dynamic Trade-offs:** Runtime control over accuracy, latency, and energy via bit-stream length adjustment.
- **FPGA Implementation:** Optimized for Xilinx Artix-7 FPGA.

## 📊 Performance Highlights (MNIST on Artix-7)

|Metric|Value|
|:---|:---|
|**Accuracy**|92.80%|
|**Computation Time per Image**|7.24 ms|
|**Energy per Image**|0.05 mJ|
|**Clock Frequency**|100 MHz|

## 🚀 Hardware Implementation

The hardware is organized into four variants to evaluate different multiplication strategies:

|Folder|Description|
|:---|:---|
|`A.StochasticComputing_FC_Share`|Fully connected layer using stochastic multipliers (AND gates).|
|`B.DSP_FC_Share`|Uses dedicated FPGA DSP slices for exact binary multiplication.|
|`C.Array_Multiplier_FC_Share`|Implements array multiplier for parallel partial product generation.|
|`D.Shift_Registe_FC_Share`|Uses shift/add sequential multiplier for low-area design.|

Each variant includes RTL code, constraint files, and simulation/testbenches.

## 💻 Software Implementation

The software side provides Python notebooks for dataset processing, model simulation, and performance analysis:

|File|Description|
|:---|:---|
|`MNIST_Dataset.ipynb`|Handles MNIST digit classification (static frames).|
|`DVS_Dataset.ipynb`|Processes DVS event-based camera data (dynamic vision).|
|`SHD_Dataset.ipynb`|Works with Spiking Heidelberg Digits (SHD) audio dataset.|
|`stochastic_curves.ipynb`|Generates accuracy/bit length trade-off curves.|

### Requirements

Install dependencies using:

```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r SoftwareImplemenetation/requirements.txt
```

## 📈 Dynamic Trade-off Control

ReSCom allows you to adjust the stochastic bit-stream length at runtime:

- Shorter length: Lower latency, lower energy, but higher approximation error.
- Longer length: Higher accuracy, but increased latency and energy.

This enables adaptive inference based on application requirements.

## 📬 Citation

If you use this work, please cite the original paper:

```bibtex
@misc{fereidani2026rescom,
      title={ReSCom: A Reconfigurable Spiking Neural Network Accelerator Using Stochastic Computing}, 
      author={Ali Alipour Fereidani and Mohammad Rasoul Roshanshah and Saeed Safari},
      year={2026},
      eprint={2606.13560},
      archivePrefix={arXiv},
      primaryClass={cs.AR}
}
```

### APA Format

```text
Fereidani, A. A., Roshanshah, M. R., & Saeed Safari. (2026). 
ReSCom: A Reconfigurable Spiking Neural Network Accelerator Using Stochastic Computing. 
arXiv preprint arXiv:2606.13560.
```

### IEEE Format

```text
A. A. Fereidani, M. R. Roshanshah, and Saeed Safari, 
"ReSCom: A Reconfigurable Spiking Neural Network Accelerator Using Stochastic Computing," 
arXiv:2606.13560, 2026.
```

### MLA Format

```text
Fereidani, Ali Alipour, et al. "ReSCom: A Reconfigurable Spiking Neural Network Accelerator Using Stochastic Computing." arXiv preprint arXiv:2606.13560 (2026).
```

## 📜 License

This repository contains the open-source implementation of the ReSCom accelerator.
The source code is distributed under the **[MIT License](LICENSE.md)**.

### Important Notice

- The original research paper (arXiv:2606.13560) is copyrighted by its authors and is available on arXiv under their standard distribution license.
- This code repository is an independent open-source implementation provided for research and educational purposes.
- The hardware and software designs in this repository are original implementations based on the paper's methodology

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements.

## 📧 Contact

For any questions, please contact the corresponding author via the email provided in the paper.
