"""
run_kilosort4_batch.py

Batch run Kilosort4 on multiple sessions.

Usage:
    python run_kilosort4_batch.py \
        --data_dir /mnt/data/Sorted/E6 \
        --settings /path/to/AndamanKS4Settings.json \
        --probe /opt/KiloSort/forKS4/40ch_2TT_5shankmap.mat

Each subfolder under data_dir should contain a file called mybinaryfile.dat.
Results will be saved to a 'kilosort4' subfolder within each session folder.
"""

import argparse
import json
import logging
from pathlib import Path

import numpy as np


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_settings(settings_path):
    """Load and flatten the nested settings JSON into a single dict."""
    with open(settings_path, 'r') as f:
        raw = json.load(f)

    settings = {}
    for section in raw.values():
        if isinstance(section, dict):
            for k, v in section.items():
                # Convert Infinity strings if needed
                if v == "Infinity" or v == float('inf'):
                    v = np.inf
                settings[k] = v

    # Remove GUI-only keys that run_kilosort doesn't accept
    for key in ['dtype_idx', 'probe_idx', 'device_idx']:
        settings.pop(key, None)

    return settings


def find_sessions(data_dir):
    """Find all subfolders containing mybinaryfile.dat."""
    data_dir = Path(data_dir)
    sessions = sorted([
        p.parent for p in data_dir.rglob('mybinaryfile.dat')
    ])
    return sessions


def get_n_chan_from_probe(probe_path):
    """Read channel count from probe file (.mat or .json)."""
    probe_path = Path(probe_path)
    if probe_path.suffix == '.json':
        with open(probe_path, 'r') as f:
            probe = json.load(f)
        return probe['n_chan']
    elif probe_path.suffix == '.mat':
        from scipy.io import loadmat
        mat = loadmat(probe_path)
        # chanMap is typically 1-indexed in .mat files
        chan_map = mat['chanMap'].flatten()
        return int(chan_map.max())
    else:
        raise ValueError(f"Unsupported probe file format: {probe_path.suffix}")


def run_batch(data_dir, settings_path, probe_path):
    from kilosort import run_kilosort

    # Load settings
    logger.info(f"Loading settings from: {settings_path}")
    settings = load_settings(settings_path)

    # Auto-detect n_chan_bin from probe file
    n_chan = get_n_chan_from_probe(probe_path)
    logger.info(f"Auto-detected n_chan_bin={n_chan} from probe file (overriding settings JSON)")
    settings['n_chan_bin'] = n_chan

    logger.info(f"Settings: {settings}")

    # Find sessions
    sessions = find_sessions(data_dir)
    if not sessions:
        logger.error(f"No sessions found in {data_dir}")
        return

    logger.info(f"Found {len(sessions)} session(s):")
    for s in sessions:
        logger.info(f"  {s}")

    # Run Kilosort on each session
    for i, session_dir in enumerate(sessions):
        binary_file = session_dir / 'mybinaryfile.dat'
        results_dir = session_dir / 'kilosort4'
        results_dir.mkdir(exist_ok=True)

        logger.info(f"\n[{i+1}/{len(sessions)}] Processing: {session_dir}")

        try:
            run_kilosort(
                settings=settings,
                filename=binary_file,
                probe_name=probe_path,
                results_dir=results_dir,
            )
            logger.info(f"  Done! Results saved to {results_dir}")
        except Exception as e:
            logger.error(f"  FAILED: {e}")
            logger.info(f"  Skipping and continuing to next session...")
            continue

    logger.info("\nBatch complete!")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Batch run Kilosort4 on multiple sessions.')
    parser.add_argument('--data_dir', required=True,
                        help='Root folder containing session subfolders')
    parser.add_argument('--settings', required=True,
                        help='Path to KS4 settings JSON file')
    parser.add_argument('--probe', required=True,
                        help='Path to probe file (.mat or .json)')
    args = parser.parse_args()

    run_batch(args.data_dir, args.settings, args.probe)
