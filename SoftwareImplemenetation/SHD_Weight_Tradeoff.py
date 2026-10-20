"""Compare software accuracy with model-specific and shared weights across IF, LIF, and Synaptic networks on SHD."""

import random
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Dataset
from tqdm import tqdm
import snntorch as snn
import tonic
import tonic.transforms as tonic_transforms
EPOCHS = 10
BATCH_SIZE = 64
LEARNING_RATE = 0.001
SEED = 0
TIME_BINS = 100
INPUT_SIZE = 700
HIDDEN_SIZE = 256
OUTPUT_SIZE = 20
THRESHOLD = 1.0
BETA = 0.98
ALPHA = 0.9
DATA_DIR = './dataset_shd'
OUTPUT_DIR = Path('shd_weight_tradeoff_results')
NUM_WORKERS = 0
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
MODES = ('IF', 'LIF', 'Synaptic')

def set_seed(seed):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)

class SHDTensorDataset(Dataset):

    def __init__(self, tonic_dataset):
        self.dataset = tonic_dataset

    def __len__(self):
        return len(self.dataset)

    def __getitem__(self, index):
        frames, label = self.dataset[index]
        frames = np.asarray(frames)
        frames = frames.reshape(frames.shape[0], -1)
        if frames.shape[1] != INPUT_SIZE:
            raise RuntimeError(f'Expected {INPUT_SIZE} SHD channels but obtained {frames.shape[1]} from shape {frames.shape}.')
        spikes = torch.from_numpy((frames > 0).astype(np.float32))
        label = torch.tensor(int(label), dtype=torch.long)
        return (spikes, label)

def make_loaders():
    frame_transform = tonic_transforms.ToFrame(sensor_size=tonic.datasets.SHD.sensor_size, n_time_bins=TIME_BINS)
    train_raw = tonic.datasets.SHD(save_to=DATA_DIR, train=True, transform=frame_transform)
    test_raw = tonic.datasets.SHD(save_to=DATA_DIR, train=False, transform=frame_transform)
    train_set = SHDTensorDataset(train_raw)
    test_set = SHDTensorDataset(test_raw)
    train_loader = DataLoader(train_set, batch_size=BATCH_SIZE, shuffle=True, num_workers=NUM_WORKERS, pin_memory=torch.cuda.is_available())
    test_loader = DataLoader(test_set, batch_size=BATCH_SIZE, shuffle=False, num_workers=NUM_WORKERS, pin_memory=torch.cuda.is_available())
    return (train_loader, test_loader)

class SNNModel(nn.Module):

    def __init__(self, mode):
        super().__init__()
        self.mode = mode
        self.fc1 = nn.Linear(INPUT_SIZE, HIDDEN_SIZE, bias=False)
        self.fc2 = nn.Linear(HIDDEN_SIZE, OUTPUT_SIZE, bias=False)
        if mode == 'IF':
            self.neuron1 = snn.Leaky(beta=1.0, threshold=THRESHOLD, reset_mechanism='zero')
            self.neuron2 = snn.Leaky(beta=1.0, threshold=THRESHOLD, reset_mechanism='zero')
        elif mode == 'LIF':
            self.neuron1 = snn.Leaky(beta=BETA, threshold=THRESHOLD, reset_mechanism='zero')
            self.neuron2 = snn.Leaky(beta=BETA, threshold=THRESHOLD, reset_mechanism='zero')
        elif mode == 'Synaptic':
            self.neuron1 = snn.Synaptic(alpha=ALPHA, beta=BETA, threshold=THRESHOLD, reset_mechanism='zero')
            self.neuron2 = snn.Synaptic(alpha=ALPHA, beta=BETA, threshold=THRESHOLD, reset_mechanism='zero')
        else:
            raise ValueError(f'Unknown mode: {mode}')

    def forward(self, x):
        batch_size = x.shape[0]
        if self.mode == 'Synaptic':
            syn1 = torch.zeros(batch_size, HIDDEN_SIZE, device=x.device)
            mem1 = torch.zeros(batch_size, HIDDEN_SIZE, device=x.device)
            syn2 = torch.zeros(batch_size, OUTPUT_SIZE, device=x.device)
            mem2 = torch.zeros(batch_size, OUTPUT_SIZE, device=x.device)
        else:
            mem1 = torch.zeros(batch_size, HIDDEN_SIZE, device=x.device)
            mem2 = torch.zeros(batch_size, OUTPUT_SIZE, device=x.device)
        output_spikes = []
        for t in range(x.shape[1]):
            cur1 = self.fc1(x[:, t, :])
            if self.mode == 'Synaptic':
                spk1, syn1, mem1 = self.neuron1(cur1, syn1, mem1)
            else:
                spk1, mem1 = self.neuron1(cur1, mem1)
            cur2 = self.fc2(spk1)
            if self.mode == 'Synaptic':
                spk2, syn2, mem2 = self.neuron2(cur2, syn2, mem2)
            else:
                spk2, mem2 = self.neuron2(cur2, mem2)
            output_spikes.append(spk2)
        return torch.stack(output_spikes)

class SharedWeightSNN(nn.Module):

    def __init__(self):
        super().__init__()
        self.fc1 = nn.Linear(INPUT_SIZE, HIDDEN_SIZE, bias=False)
        self.fc2 = nn.Linear(HIDDEN_SIZE, OUTPUT_SIZE, bias=False)
        self.if1 = snn.Leaky(beta=1.0, threshold=THRESHOLD, reset_mechanism='zero')
        self.if2 = snn.Leaky(beta=1.0, threshold=THRESHOLD, reset_mechanism='zero')
        self.lif1 = snn.Leaky(beta=BETA, threshold=THRESHOLD, reset_mechanism='zero')
        self.lif2 = snn.Leaky(beta=BETA, threshold=THRESHOLD, reset_mechanism='zero')
        self.syn1 = snn.Synaptic(alpha=ALPHA, beta=BETA, threshold=THRESHOLD, reset_mechanism='zero')
        self.syn2 = snn.Synaptic(alpha=ALPHA, beta=BETA, threshold=THRESHOLD, reset_mechanism='zero')

    def forward(self, x, mode):
        batch_size = x.shape[0]
        if mode == 'Synaptic':
            syn1_state = torch.zeros(batch_size, HIDDEN_SIZE, device=x.device)
            mem1 = torch.zeros(batch_size, HIDDEN_SIZE, device=x.device)
            syn2_state = torch.zeros(batch_size, OUTPUT_SIZE, device=x.device)
            mem2 = torch.zeros(batch_size, OUTPUT_SIZE, device=x.device)
        else:
            mem1 = torch.zeros(batch_size, HIDDEN_SIZE, device=x.device)
            mem2 = torch.zeros(batch_size, OUTPUT_SIZE, device=x.device)
        output_spikes = []
        for t in range(x.shape[1]):
            cur1 = self.fc1(x[:, t, :])
            if mode == 'IF':
                spk1, mem1 = self.if1(cur1, mem1)
            elif mode == 'LIF':
                spk1, mem1 = self.lif1(cur1, mem1)
            elif mode == 'Synaptic':
                spk1, syn1_state, mem1 = self.syn1(cur1, syn1_state, mem1)
            else:
                raise ValueError(f'Unknown mode: {mode}')
            cur2 = self.fc2(spk1)
            if mode == 'IF':
                spk2, mem2 = self.if2(cur2, mem2)
            elif mode == 'LIF':
                spk2, mem2 = self.lif2(cur2, mem2)
            else:
                spk2, syn2_state, mem2 = self.syn2(cur2, syn2_state, mem2)
            output_spikes.append(spk2)
        return torch.stack(output_spikes)

def train_specific(model, train_loader, name):
    model.train()
    optimizer = torch.optim.Adam(model.parameters(), lr=LEARNING_RATE)
    criterion = nn.CrossEntropyLoss()
    for epoch in range(EPOCHS):
        pbar = tqdm(train_loader, desc=f'Training separate {name}: {epoch + 1}/{EPOCHS}')
        for spikes, labels in pbar:
            spikes = spikes.to(DEVICE, non_blocking=True)
            labels = labels.to(DEVICE, non_blocking=True)
            optimizer.zero_grad(set_to_none=True)
            out_spikes = model(spikes)
            logits = out_spikes.sum(dim=0)
            loss = criterion(logits, labels)
            loss.backward()
            optimizer.step()
            pbar.set_postfix(loss=f'{loss.item():.4f}')

def train_shared(model, train_loader):
    model.train()
    optimizer = torch.optim.Adam(model.parameters(), lr=LEARNING_RATE)
    criterion = nn.CrossEntropyLoss()
    for epoch in range(EPOCHS):
        pbar = tqdm(train_loader, desc=f'Training ONE shared weight set: {epoch + 1}/{EPOCHS}')
        for spikes, labels in pbar:
            spikes = spikes.to(DEVICE, non_blocking=True)
            labels = labels.to(DEVICE, non_blocking=True)
            optimizer.zero_grad(set_to_none=True)
            losses = []
            for mode in MODES:
                out_spikes = model(spikes, mode)
                logits = out_spikes.sum(dim=0)
                losses.append(criterion(logits, labels))
            loss = torch.stack(losses).mean()
            loss.backward()
            optimizer.step()
            pbar.set_postfix(loss=f'{loss.item():.4f}')

@torch.no_grad()
def evaluate_specific(model, test_loader):
    model.eval()
    correct = 0
    total = 0
    for spikes, labels in test_loader:
        spikes = spikes.to(DEVICE, non_blocking=True)
        labels = labels.to(DEVICE, non_blocking=True)
        out_spikes = model(spikes)
        predictions = out_spikes.sum(dim=0).argmax(dim=1)
        correct += (predictions == labels).sum().item()
        total += labels.numel()
    return 100.0 * correct / total

@torch.no_grad()
def evaluate_shared(model, test_loader, mode):
    model.eval()
    correct = 0
    total = 0
    for spikes, labels in test_loader:
        spikes = spikes.to(DEVICE, non_blocking=True)
        labels = labels.to(DEVICE, non_blocking=True)
        out_spikes = model(spikes, mode)
        predictions = out_spikes.sum(dim=0).argmax(dim=1)
        correct += (predictions == labels).sum().item()
        total += labels.numel()
    return 100.0 * correct / total

def main():
    set_seed(SEED)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print('\n======================================')
    print('ReSCom SHD shared-weight trade-off')
    print('======================================')
    print(f'Device: {DEVICE}')
    print(f'Network: {INPUT_SIZE}-{HIDDEN_SIZE}-{OUTPUT_SIZE}')
    print(f'Temporal bins: {TIME_BINS}')
    print('SHD will be downloaded automatically by Tonic.\n')
    train_loader, test_loader = make_loaders()
    sample_spikes, _ = next(iter(train_loader))
    print(f'Input batch shape: {tuple(sample_spikes.shape)}')
    print('Expected: [batch, TIME_BINS, 700]\n')
    specific_accuracy = {}
    for i, mode in enumerate(MODES):
        set_seed(SEED + i)
        model = SNNModel(mode).to(DEVICE)
        train_specific(model, train_loader, mode)
        acc = evaluate_specific(model, test_loader)
        specific_accuracy[mode] = acc
        print(f'Separate {mode:8s} accuracy: {acc:.2f}%')
        del model
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
    set_seed(SEED)
    shared_model = SharedWeightSNN().to(DEVICE)
    train_shared(shared_model, train_loader)
    shared_accuracy = {}
    for mode in MODES:
        acc = evaluate_shared(shared_model, test_loader, mode)
        shared_accuracy[mode] = acc
        print(f'Shared   {mode:8s} accuracy: {acc:.2f}%')
    rows = []
    for mode in MODES:
        change = shared_accuracy[mode] - specific_accuracy[mode]
        rows.append({'Neuron model': mode, 'Model-specific accuracy (%)': specific_accuracy[mode], 'Shared-weight accuracy (%)': shared_accuracy[mode], 'Shared - specific (percentage points)': change})
    accuracy_df = pd.DataFrame(rows)
    accuracy_df.to_csv(OUTPUT_DIR / 'accuracy_tradeoff_shd.csv', index=False)
    specific_values = [specific_accuracy[m] for m in MODES]
    shared_values = [shared_accuracy[m] for m in MODES]
    x = np.arange(len(MODES))
    width = 0.35
    fig, ax = plt.subplots(figsize=(7, 4))
    ax.bar(x - width / 2, specific_values, width, label='Model-specific weights')
    ax.bar(x + width / 2, shared_values, width, label='One shared weight set')
    ax.set_xticks(x)
    ax.set_xticklabels(MODES)
    ax.set_ylabel('SHD test accuracy (%)')
    ax.set_xlabel('Neuron model')
    ax.legend()
    ax.grid(axis='y', alpha=0.25)
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / 'shared_vs_specific_accuracy_shd.png', dpi=300, bbox_inches='tight')
    fig.savefig(OUTPUT_DIR / 'shared_vs_specific_accuracy_shd.pdf', bbox_inches='tight')
    plt.close(fig)
    mean_specific = float(np.mean(specific_values))
    mean_shared = float(np.mean(shared_values))
    mean_change = mean_shared - mean_specific
    print('\n\n======================================')
    print('\nSHD ACCURACY TABLE')
    print(accuracy_df.to_string(index=False, float_format=lambda value: f'{value:.2f}'))
    print('\nACCURACY CHANGE ONLY')
    for mode in MODES:
        change = shared_accuracy[mode] - specific_accuracy[mode]
        print(f'{mode:8s}: {change:+.2f} percentage points')
    print(f'Average : {mean_change:+.2f} percentage points')
    print('\nFiles saved in:')
    print(OUTPUT_DIR.resolve())
if __name__ == '__main__':
    main()
