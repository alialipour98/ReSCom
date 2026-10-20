# ReSCom: Reconfigurable SNN Accelerator Using Stochastic Computing

This repository contains the hardware and software implementation of **ReSCom**, a reconfigurable Spiking Neural Network (SNN) accelerator that leverages stochastic computing for efficient inference on FPGA.

## 📄 Paper Reference

**Title:** ReSCom: A reconfigurable spiking neural network accelerator using stochastic computing  
**Authors:** Ali Alipour Fereidani, Mohammad Rasoul Roshanshah, and Saeed Safari
**Published:** Integration, Vol. 112, 2027, Art.No. 102906, ISSN 0167-9260  
**DOI:** 10.1016/j.vlsi.2026.102906
**Link:** [https://www.sciencedirect.com/science/article/pii/S0167926026002610](https://www.sciencedirect.com/science/article/pii/S0167926026002610)

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
    ├── MNIST_Weight_Tradeoff.py
    ├── requirements.txt
    ├── SHD_Dataset.ipynb
    ├── SHD_Weight_Tradeoff.py
    └── stochastic_curves.ipynb

```

## 🧠 Key Features

- **Stochastic Computing:** Uses stochastic multiplication for neuron decay operations to reduce hardware complexity.
- **Reconfigurable Neuron Models:** Supports **Integrate-and-Fire (IF)**, **Leaky Integrate-and-Fire (LIF)**, and **Synaptic** neuron models through a shared neuron datapath. Switching independently trained models also requires loading their corresponding weights unless those weights are already resident in BRAM.
- **Exact Fixed-Point Operations:** Preserves exact addition/subtraction for stable recurrent updates.
- **Dynamic Trade-offs:** Runtime control over accuracy, latency, and energy via bit-stream length adjustment.
- **FPGA Implementation:** Optimized for Xilinx Artix-7 FPGA.

## 📊 Performance Highlights (MNIST on Artix-7)

Reported in the revised manuscript for the **LIF** model with a **16-bit stochastic bit-stream length**, a **784–256–10** network, and **10 time steps**.

|Metric|Value|
|:---|:---|
|**Accuracy**|95.52%|
|**Computation Time per Image**|20.752 ms|
|**Operational Energy per Image**|0.1868 mJ (approximately 0.187 mJ)|
|**Clock Frequency (comparison operating point)**|100 MHz|

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

ReSCom allows you to adjust the stochastic bit-stream length at runtime; the revised manuscript evaluates lengths from **2 to 1024 bits**:

- Shorter length: Lower latency and energy, but generally higher stochastic approximation error for LIF and Synaptic models.
- Longer length: Can reduce stochastic approximation error, but increases latency and energy; classification accuracy does not necessarily improve monotonically.
- IF has no decay multiplication and does not use the stochastic multiplier, so its energy remains constant and its accuracy is largely insensitive to bit-stream length.

Moderate lengths provide useful operating points, while very long streams offer limited additional accuracy benefit. Increasing stream length does not eliminate fixed-point quantization error. This enables adaptive inference based on application requirements.

## 📬 Citation

If you use this work, please cite the original paper:

```bibtex
@article{ReSCom,
title = {ReSCom: A reconfigurable spiking neural network accelerator using stochastic computing},
journal = {Integration},
volume = {112},
pages = {102906},
year = {2027},
issn = {0167-9260},
doi = {https://doi.org/10.1016/j.vlsi.2026.102906},
url = {https://www.sciencedirect.com/science/article/pii/S0167926026002610},
author = {Ali Alipour Fereidani and Mohammad Rasoul Roshanshah and Saeed Safari},
keywords = {Neuromorphic computing, Spiking neural networks, Stochastic computing, Reconfigurable accelerator, FPGA implementation, Low-power design},
abstract = {Spiking Neural Networks (SNNs) offer energy-efficient inference through event-driven computation, but their hardware implementation remains challenging because neuron-state updates require costly arithmetic and are sensitive to approximation errors. This paper presents ReSCom, a reconfigurable FPGA accelerator that combines stochastic multiplication with exact fixed-point addition, subtraction, and state accumulation. A unified neuron core supports Integrate-and-Fire (IF), Leaky Integrate-and-Fire (LIF), and Synaptic models, enabling runtime adaptation without duplicating hardware. ReSCom is evaluated on MNIST image classification and the Spiking Heidelberg Digits (SHD) auditory benchmark, which provides a more demanding temporally structured workload with 700 input channels. At a 16-bit stochastic precision, the LIF configuration achieves 95.52% accuracy on MNIST and 71.09% on SHD, with operational energies of 0.1868 mJ and 0.1674 mJ per sample, respectively. A bit-stream study from 2 to 1024 bits shows that moderate stream lengths substantially improve the accuracy of stateful neuron models, whereas very long streams increase energy with limited additional benefit. These results demonstrate that ReSCom enables configurable accuracy–energy trade-offs across both visual and auditory SNN workloads.}
}
```

## 📜 License

This repository contains the open-source implementation of the ReSCom accelerator.
The source code is distributed under the **[MIT License](LICENSE.md)**.

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements.

## 📧 Contact

For any questions, please contact the authors via the emails provided in the paper.
