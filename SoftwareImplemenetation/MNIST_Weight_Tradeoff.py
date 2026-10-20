"""Compare model-specific and shared weights across IF, LIF, and Synaptic networks on MNIST, including estimated weight reload costs."""

import random
from pathlib import Path
import matplotlib.pyplot as plt
import pandas as pd
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
from tqdm import tqdm
import snntorch as snn
EPOCHS = 10
BATCH_SIZE = 128
LEARNING_RATE = 0.001
TIME_STEPS = 10
SEED = 0
INPUT_SIZE = 784
HIDDEN_SIZE = 256
OUTPUT_SIZE = 10
THRESHOLD = 1.0
BETA = 0.98
ALPHA = 0.9
WEIGHT_BITS = 16
CLOCK_MHZ = 100.0
LOADER_WEIGHTS_PER_CYCLE = None
OUTPUT_DIR = Path('weight_tradeoff_results')
DATA_DIR = './dataset'
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
MODES = ('IF', 'LIF', 'Synaptic')

def set_seed(seed):
    random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)

def rate_encode(x):
    x = x.unsqueeze(0).repeat(TIME_STEPS, 1, 1)
    return (torch.rand_like(x) < x).float()

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

    def forward(self, x):
        batch = x.shape[1]
        if self.mode == 'Synaptic':
            syn1 = torch.zeros(batch, HIDDEN_SIZE, device=x.device)
            mem1 = torch.zeros(batch, HIDDEN_SIZE, device=x.device)
            syn2 = torch.zeros(batch, OUTPUT_SIZE, device=x.device)
            mem2 = torch.zeros(batch, OUTPUT_SIZE, device=x.device)
        else:
            mem1 = torch.zeros(batch, HIDDEN_SIZE, device=x.device)
            mem2 = torch.zeros(batch, OUTPUT_SIZE, device=x.device)
        out_spikes = []
        for t in range(TIME_STEPS):
            cur1 = self.fc1(x[t])
            if self.mode == 'Synaptic':
                spk1, syn1, mem1 = self.neuron1(cur1, syn1, mem1)
            else:
                spk1, mem1 = self.neuron1(cur1, mem1)
            cur2 = self.fc2(spk1)
            if self.mode == 'Synaptic':
                spk2, syn2, mem2 = self.neuron2(cur2, syn2, mem2)
            else:
                spk2, mem2 = self.neuron2(cur2, mem2)
            out_spikes.append(spk2)
        return torch.stack(out_spikes)

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
        batch = x.shape[1]
        if mode == 'Synaptic':
            syn1_state = torch.zeros(batch, HIDDEN_SIZE, device=x.device)
            mem1 = torch.zeros(batch, HIDDEN_SIZE, device=x.device)
            syn2_state = torch.zeros(batch, OUTPUT_SIZE, device=x.device)
            mem2 = torch.zeros(batch, OUTPUT_SIZE, device=x.device)
        else:
            mem1 = torch.zeros(batch, HIDDEN_SIZE, device=x.device)
            mem2 = torch.zeros(batch, OUTPUT_SIZE, device=x.device)
        out_spikes = []
        for t in range(TIME_STEPS):
            cur1 = self.fc1(x[t])
            if mode == 'IF':
                spk1, mem1 = self.if1(cur1, mem1)
            elif mode == 'LIF':
                spk1, mem1 = self.lif1(cur1, mem1)
            else:
                spk1, syn1_state, mem1 = self.syn1(cur1, syn1_state, mem1)
            cur2 = self.fc2(spk1)
            if mode == 'IF':
                spk2, mem2 = self.if2(cur2, mem2)
            elif mode == 'LIF':
                spk2, mem2 = self.lif2(cur2, mem2)
            else:
                spk2, syn2_state, mem2 = self.syn2(cur2, syn2_state, mem2)
            out_spikes.append(spk2)
        return torch.stack(out_spikes)

def make_loaders():
    transform = transforms.Compose([transforms.ToTensor(), transforms.Lambda(lambda x: x.view(-1))])
    train_set = datasets.MNIST(DATA_DIR, train=True, download=True, transform=transform)
    test_set = datasets.MNIST(DATA_DIR, train=False, download=True, transform=transform)
    train_loader = DataLoader(train_set, batch_size=BATCH_SIZE, shuffle=True)
    test_loader = DataLoader(test_set, batch_size=BATCH_SIZE, shuffle=False)
    return (train_loader, test_loader)

def train_specific(model, train_loader, name):
    model.train()
    optimizer = torch.optim.Adam(model.parameters(), lr=LEARNING_RATE)
    criterion = nn.CrossEntropyLoss()
    for epoch in range(EPOCHS):
        pbar = tqdm(train_loader, desc=f'Training separate {name}: {epoch + 1}/{EPOCHS}')
        for images, labels in pbar:
            images = images.to(DEVICE)
            labels = labels.to(DEVICE)
            x_spk = rate_encode(images)
            optimizer.zero_grad()
            out_spk = model(x_spk)
            logits = out_spk.sum(dim=0)
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
        for images, labels in pbar:
            images = images.to(DEVICE)
            labels = labels.to(DEVICE)
            x_spk = rate_encode(images)
            optimizer.zero_grad()
            losses = []
            for mode in MODES:
                out_spk = model(x_spk, mode)
                logits = out_spk.sum(dim=0)
                losses.append(criterion(logits, labels))
            loss = sum(losses) / len(losses)
            loss.backward()
            optimizer.step()
            pbar.set_postfix(loss=f'{loss.item():.4f}')

@torch.no_grad()
def evaluate_specific(model, test_loader):
    model.eval()
    correct = 0
    total = 0
    for images, labels in test_loader:
        images = images.to(DEVICE)
        labels = labels.to(DEVICE)
        x_spk = rate_encode(images)
        out_spk = model(x_spk)
        pred = out_spk.sum(dim=0).argmax(dim=1)
        correct += (pred == labels).sum().item()
        total += labels.numel()
    return 100.0 * correct / total

@torch.no_grad()
def evaluate_shared(model, test_loader, mode):
    model.eval()
    correct = 0
    total = 0
    for images, labels in test_loader:
        images = images.to(DEVICE)
        labels = labels.to(DEVICE)
        x_spk = rate_encode(images)
        out_spk = model(x_spk, mode)
        pred = out_spk.sum(dim=0).argmax(dim=1)
        correct += (pred == labels).sum().item()
        total += labels.numel()
    return 100.0 * correct / total

def calculate_reload_cost():
    number_of_weights = INPUT_SIZE * HIDDEN_SIZE + HIDDEN_SIZE * OUTPUT_SIZE
    total_bits = number_of_weights * WEIGHT_BITS
    total_bytes = total_bits / 8
    total_kib = total_bytes / 1024
    if LOADER_WEIGHTS_PER_CYCLE is None:
        reload_cycles = None
        reload_us = None
    else:
        reload_cycles = number_of_weights / LOADER_WEIGHTS_PER_CYCLE
        reload_us = reload_cycles / (CLOCK_MHZ * 1000000.0) * 1000000.0
    return (number_of_weights, total_kib, reload_cycles, reload_us)

def main():
    set_seed(SEED)
    OUTPUT_DIR.mkdir(exist_ok=True)
    print('\n======================================')
    print('ReSCom shared-weight trade-off test')
    print('======================================')
    print(f'Device: {DEVICE}')
    print('MNIST will be downloaded automatically.\n')
    train_loader, test_loader = make_loaders()
    specific_accuracy = {}
    for i, mode in enumerate(MODES):
        set_seed(SEED + i)
        model = SNNModel(mode).to(DEVICE)
        train_specific(model, train_loader, mode)
        set_seed(100)
        acc = evaluate_specific(model, test_loader)
        specific_accuracy[mode] = acc
        print(f'Separate {mode:8s} accuracy: {acc:.2f}%')
    set_seed(SEED)
    shared_model = SharedWeightSNN().to(DEVICE)
    train_shared(shared_model, train_loader)
    shared_accuracy = {}
    for mode in MODES:
        set_seed(100)
        acc = evaluate_shared(shared_model, test_loader, mode)
        shared_accuracy[mode] = acc
        print(f'Shared   {mode:8s} accuracy: {acc:.2f}%')
    rows = []
    for mode in MODES:
        change = shared_accuracy[mode] - specific_accuracy[mode]
        rows.append({'Neuron model': mode, 'Model-specific weights accuracy (%)': specific_accuracy[mode], 'One shared weight set accuracy (%)': shared_accuracy[mode], 'Shared - specific (percentage points)': change})
    accuracy_df = pd.DataFrame(rows)
    accuracy_df.to_csv(OUTPUT_DIR / 'accuracy_tradeoff.csv', index=False)
    number_of_weights, weight_set_kib, reload_cycles, reload_us = calculate_reload_cost()
    cost_rows = [{'Strategy': 'Model-specific weights', 'Number of trained weight sets': 3, 'Data transferred when changing mode (KiB)': weight_set_kib, 'Reload cycles': 'N/A' if reload_cycles is None else reload_cycles, 'Reload latency (us)': 'N/A' if reload_us is None else reload_us}, {'Strategy': 'One shared weight set', 'Number of trained weight sets': 1, 'Data transferred when changing mode (KiB)': 0, 'Reload cycles': 0, 'Reload latency (us)': 0}]
    cost_df = pd.DataFrame(cost_rows)
    cost_df.to_csv(OUTPUT_DIR / 'weight_reload_cost.csv', index=False)
    x = range(len(MODES))
    width = 0.35
    fig, ax = plt.subplots(figsize=(7, 4))
    specific_values = [specific_accuracy[m] for m in MODES]
    shared_values = [shared_accuracy[m] for m in MODES]
    ax.bar([v - width / 2 for v in x], specific_values, width, label='Model-specific weights')
    ax.bar([v + width / 2 for v in x], shared_values, width, label='One shared weight set')
    ax.set_xticks(list(x))
    ax.set_xticklabels(MODES)
    ax.set_ylabel('Software inference accuracy (%)')
    ax.set_xlabel('Neuron model')
    ax.legend()
    ax.grid(axis='y', alpha=0.25)
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / 'shared_vs_specific_accuracy.png', dpi=300)
    fig.savefig(OUTPUT_DIR / 'shared_vs_specific_accuracy.pdf')
    plt.close(fig)
    mean_specific = sum(specific_values) / 3
    mean_shared = sum(shared_values) / 3
    mean_change = mean_shared - mean_specific
    print('\n\n======================================')
    print('\nACCURACY TABLE')
    print(accuracy_df.to_string(index=False))
    print('\nWEIGHT RELOAD COST')
    print(f'Number of FC weights per set = {number_of_weights:,}')
    print(f'Stored bits per weight       = {WEIGHT_BITS}')
    print(f'Size of one weight set       = {weight_set_kib:.2f} KiB')
    if reload_cycles is None:
        print('Reload latency               = NOT CALCULATED (loader throughput not supplied)')
    else:
        print(f'Reload cycles                = {reload_cycles:.0f}')
        print(f'Reload latency               = {reload_us:.2f} us')
    print('\nAVERAGES')
    print(f'Mean model-specific accuracy = {mean_specific:.2f}%')
    print(f'Mean shared-weight accuracy  = {mean_shared:.2f}%')
    print(f'Mean shared-specific change  = {mean_change:.2f} percentage points')
    print('\nFiles saved in:')
    print(OUTPUT_DIR.resolve())
if __name__ == '__main__':
    main()
