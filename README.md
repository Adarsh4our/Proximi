# Proximi

A local-first desktop photo management application built with Python and Qt Quick.

Proximi helps you organize, scan, and browse large image collections with a responsive, modern interface — all without cloud dependencies.

## Features

- **Folder Scanning** — Recursively discover images (JPG, PNG, WEBP, HEIC)
- **Async Thumbnail Pipeline** — Background generation with persistent WEBP cache
- **SQLite Metadata** — All image metadata stored locally for fast queries
- **Progressive Grid** — Virtualized rendering for smooth scrolling through 1000+ images
- **Debug Panel** — Built-in diagnostics overlay (`Ctrl+Shift+D`) for runtime inspection

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Qt Quick / QML |
| Backend | Python 3.11+, PySide6 |
| Database | SQLite via SQLAlchemy |
| Imaging | Pillow, pillow-heif |
| Architecture | Layered (UI → Controllers → Services → Repository) |

## Getting Started

### Prerequisites

- Python 3.11+
- pip

### Setup

```bash
# Clone the repository
git clone https://github.com/adarsh290/Summer-project.git
cd Summer-project

# Create virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\activate

# Activate (macOS/Linux)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Run

```bash
python main.py
```

## Usage

1. Click **Select Folder** in the top bar to choose an image directory
2. Click **Scan** to begin async image discovery and thumbnail generation
3. Browse your images in the responsive grid
4. Press `Ctrl+Shift+D` to toggle the developer debug panel

## Project Structure

```
Summer-project/
├── main.py                          # Application entry point
├── requirements.txt
├── app/
│   ├── controllers/                 # QML ↔ Python bridges
│   │   ├── app_controller.py
│   │   ├── scan_controller.py       # Scan lifecycle + ImageViewModel
│   │   └── debug_controller.py      # Debug panel toggle + snapshot
│   ├── services/                    # Business logic
│   │   ├── scan_service.py          # Folder discovery + pipeline
│   │   ├── scan_worker.py           # QRunnable async worker
│   │   ├── thumbnail_service.py     # Pillow thumbnails + WEBP cache
│   │   └── debug_service.py         # Runtime metrics collector
│   ├── database/                    # Persistence
│   │   ├── connection.py            # SQLite/SQLAlchemy setup
│   │   └── image_repository.py      # CRUD operations
│   ├── models/                      # ORM models
│   │   ├── image.py
│   │   └── scan_session.py
│   └── ui/qml/                      # Qt Quick UI
│       ├── Main.qml
│       ├── themes/Theme.qml
│       └── components/              # Reusable UI components
└── data/                            # Local runtime data (gitignored)
    ├── thumbnails/                   # Cached WEBP thumbnails
    └── proximi.db                   # SQLite database
```

## Architecture

```
QML (presentation only)
  ↓ signals/slots
Controllers (orchestration, view-model transforms)
  ↓
Services (business logic, async workers)
  ↓
Repository (database persistence)
```

- **QML** handles layout and rendering — zero business logic
- **Controllers** bridge Python ↔ QML, transform data via `ImageViewModel`
- **Services** handle scanning, thumbnailing, and metrics
- **Repository** abstracts all SQLite operations

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+D` | Toggle debug panel |

## License

This project is for educational and personal use.
