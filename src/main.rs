#![allow(dead_code, unused_variables, unused_labels)]

use std::{
    fs, io::{self}, time::{Duration, Instant}
};

use color_eyre::Result;
use mpd::Client;
use ratatui::{
    buffer::Buffer,
    crossterm::event::{self, Event, KeyCode, KeyEventKind},
    layout::{Constraint, Layout, Rect},
    style::Stylize,
    text::Line,
    widgets::{Block, Padding, Paragraph, Widget, Wrap},
    DefaultTerminal,
};
use walkdir::{DirEntry, WalkDir};

fn main() -> Result<()> {
    //
    //
    let mut c_song = current_song().unwrap();
    c_song += ".lrc";
    let m_dir = dirs::audio_dir().unwrap();
    let walker = WalkDir::new(m_dir).into_iter();
    'iter_in_music_dir: for entry in walker
    /*.filter_entry(|e| match_name(e, "Eastside")) */
    {
        let entry = entry.unwrap();

        if entry
            .path()
            .to_string_lossy()
            .to_lowercase()
            .trim()
            .to_string()
            .as_str()
            .contains(c_song.to_lowercase().trim().to_string().as_str())
        {
            break 'iter_in_music_dir;
        }
    }
    //
    //

    color_eyre::install()?;
    let terminal = ratatui::init();
    let app_result = App::new().run(terminal);
    ratatui::restore();
    app_result
}

#[derive(Debug)]
struct App {
    should_exit: bool,
    scroll: u16,
    last_tick: Instant,
}

impl App {
    /// The duration between each tick.
    const TICK_RATE: Duration = Duration::from_millis(250);

    /// Create a new instance of the app.
    fn new() -> Self {
        Self {
            should_exit: false,
            scroll: 0,
            last_tick: Instant::now(),
        }
    }

    /// Run the app until the user exits.
    fn run(mut self, mut terminal: DefaultTerminal) -> Result<()> {
        while !self.should_exit {
            terminal.draw(|frame| frame.render_widget(&self, frame.area()))?;
            self.handle_events()?;
            if self.last_tick.elapsed() >= Self::TICK_RATE {
                self.on_tick();
                self.last_tick = Instant::now();
            }
        }
        Ok(())
    }

    /// Handle events from the terminal.
    fn handle_events(&mut self) -> io::Result<()> {
        let timeout = Self::TICK_RATE.saturating_sub(self.last_tick.elapsed());
        while event::poll(timeout)? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press && key.code == KeyCode::Char('w') {
                    self.should_exit = true;
                }
            }
        }
        Ok(())
    }

    /// Update the app state on each tick.
    fn on_tick(&mut self) {
        self.scroll = (self.scroll + 1) % 100;
    }
}

impl Widget for &App {
    fn render(self, area: Rect, buf: &mut Buffer) {
        let c_song = current_song().unwrap();
        let areas = Layout::vertical([Constraint::Min(10); 1]).split(area);
        Paragraph::new(create_lines())
            .block(title_block(format!(" {} ", c_song).as_str()))
            .blue()
            .centered()
            .wrap(Wrap { trim: true })
            .scroll((self.scroll, 0))
            .render(areas[0], buf);
    }
}

/// Create a bordered block with a title.
fn title_block(title: &str) -> Block {
    Block::bordered()
        .white()
        .padding(Padding::symmetric(0, 1))
        .title(title.bold().into_centered_line())
}

fn get_lrc() -> String {
    let mut c_song = current_song().unwrap();
    c_song += ".lrc";
    let m_dir = dirs::audio_dir().unwrap();
    let walker = WalkDir::new(m_dir).into_iter();
    'iter_in_music_dir: for entry in walker
    /*.filter_entry(|e| match_name(e, "Eastside")) */
    {
        let entry = entry.unwrap();

        if entry
            .path()
            .to_string_lossy()
            .to_lowercase()
            .trim()
            .to_string()
            .as_str()
            .contains(c_song.to_lowercase().trim().to_string().as_str())
        {
            return entry.path().to_string_lossy().to_string();
        }
    }
    String::from("")
}

fn is_hidden(entry: &DirEntry) -> bool {
    entry
        .file_name()
        .to_str()
        .map(|s| s.starts_with("."))
        .unwrap_or(false)
}

fn match_name(entry: &DirEntry, pattern: &str) -> bool {
    entry
        .file_name()
        .to_str()
        .map(|s| s.contains(pattern))
        .unwrap_or(false)
}

fn current_song() -> anyhow::Result<String, mpd::error::Error> {
    let mut client = Client::connect("127.0.0.1:6600")?;
    let title = client.currentsong().map(|s| {
        s.map(|t| t.title.unwrap_or("Failed to get song title".to_string()))
            .unwrap_or("Failed to get song title".to_string())
    })?;
    Ok(title)
}

/// Create some lines to display in the paragraph.
fn create_lines() -> Vec<Line<'static>> {
    let lrc_file = get_lrc();
    let lrc = fs::read_to_string(lrc_file).unwrap();
    let lyrics: Vec<Line> = lrc
        .lines()
        .map(|line| Line::from(line.to_string()))
        .collect();
    lyrics
}
