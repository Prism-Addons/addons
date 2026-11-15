-- a light touch on prism's own look: colors come from the active palette so light and dark themes both work,
-- only the accent and the rounding are ours

local settings = prism.settings

local function accent(alpha)
    local color = settings.get("accent")
    local red, green, blue = tonumber(color:sub(4, 5), 16), tonumber(color:sub(6, 7), 16), tonumber(color:sub(8, 9), 16)
    return string.format("rgba(%d, %d, %d, %.2f)", red, green, blue, alpha)
end

local function css()
    local radius = settings.get("radius")
    local text = ([[
QToolBar { border: none; padding: 4px; spacing: 2px; }
QToolBar QToolButton { border: 1px solid transparent; border-radius: RADIUSpx; padding: 5px 9px; }
QToolBar QToolButton:hover { background: SOFT; border-color: LINE; }
QToolBar QToolButton:pressed, QToolBar QToolButton:checked { background: STRONG; }

InstanceView { border: 1px solid palette(mid); border-radius: RADIUSpx; background: palette(base);
    selection-background-color: STRONG; selection-color: palette(text); }

QPushButton { border: 1px solid palette(mid); border-radius: RADIUSpx; padding: 5px 14px; background: palette(button); }
QPushButton:hover { border-color: ACCENT; background: SOFT; }
QPushButton:pressed { background: STRONG; }
QPushButton:default { border-color: ACCENT; }
QPushButton:disabled { color: palette(mid); }

QLineEdit, QPlainTextEdit, QTextEdit, QSpinBox, QDoubleSpinBox, QComboBox {
    border: 1px solid palette(mid); border-radius: RADIUSpx; padding: 4px 6px; background: palette(base);
    selection-background-color: STRONG; selection-color: palette(text); }
QLineEdit:focus, QPlainTextEdit:focus, QTextEdit:focus, QSpinBox:focus, QComboBox:focus { border-color: ACCENT; }

QListView, QTreeView, QTableView { border: 1px solid palette(mid); border-radius: RADIUSpx;
    selection-background-color: STRONG; selection-color: palette(text); }

QMenu { border: 1px solid palette(mid); border-radius: RADIUSpx; padding: 4px; background: palette(window); }
QMenu::item { padding: 5px 18px; border-radius: 6px; }
QMenu::item:selected { background: STRONG; color: palette(text); }
QMenu::separator { height: 1px; background: palette(mid); margin: 4px 8px; }

QTabBar::tab { padding: 6px 14px; border: none; border-bottom: 2px solid transparent; }
QTabBar::tab:selected { border-bottom-color: ACCENT; }
QTabBar::tab:hover { background: SOFT; }

QCheckBox::indicator:checked, QRadioButton::indicator:checked { background: ACCENT; border: 1px solid ACCENT; border-radius: 3px; }
QProgressBar { border: 1px solid palette(mid); border-radius: RADIUSpx; text-align: center; }
QProgressBar::chunk { background: ACCENT; border-radius: RADIUSpx; }
QScrollBar:vertical { width: 10px; background: transparent; }
QScrollBar::handle:vertical { background: palette(mid); border-radius: 4px; min-height: 24px; }
QScrollBar::add-line, QScrollBar::sub-line { height: 0; }
]]):gsub("RADIUS", tostring(radius)):gsub("STRONG", accent(0.35)):gsub("SOFT", accent(0.14)):gsub("LINE", accent(0.45)):gsub("ACCENT", accent(1))
    return text
end

prism.ui.style(css())
settings.on_change(function() prism.ui.style(css()) end)
