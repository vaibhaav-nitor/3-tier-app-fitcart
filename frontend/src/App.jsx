import React from 'react';
import Home from './app/App';
import FitnessAdvisor from './fitness-advisor/FitnessAdvisor';
import './App.css';

const SPORTS = [
  { icon: '🏃', label: 'Running' },
  { icon: '🏋️', label: 'Gym' },
  { icon: '🚴', label: 'Cycling' },
  { icon: '🧘', label: 'Yoga' },
  { icon: '🏊', label: 'Swimming' },
  { icon: '⚽', label: 'Football' },
  { icon: '🎾', label: 'Tennis' },
  { icon: '🥊', label: 'Boxing' },
];

function App() {
  const [advisorPick, setAdvisorPick] = React.useState({ exercise: '', diet: '' });

  const handleAdvisorApply = (exercise, diet) => {
    setAdvisorPick({ exercise, diet });
  };

  return (
    <div className="page-wrapper">

      {/* Top bar */}
      <div className="topbar">
        <span>Free delivery on orders over ₹999</span>
        <span>|</span>
        <span>🏪 Find a Store</span>
        <span>|</span>
        <span>Help &amp; Contact</span>
      </div>

      {/* Header */}
      <header className="dec-header">
        <div className="dec-logo">
          <span className="dec-logo-text">FIT</span>
          <span className="dec-logo-badge">CART</span>
        </div>
        <div className="dec-search">
          <span className="search-icon">🔍</span>
          <input type="text" placeholder="What sport are you looking for?" />
          <button className="dec-search-btn">Search</button>
        </div>
        <div className="dec-header-actions">
          <button className="action-btn">
            <span className="action-icon">📍</span>
            <span className="action-label">Store</span>
          </button>
          <button className="action-btn">
            <span className="action-icon">👤</span>
            <span className="action-label">Account</span>
          </button>
          <button className="action-btn">
            <span className="action-icon">❤️</span>
            <span className="action-label">Wishlist</span>
          </button>
          <button className="action-btn cart-btn">
            <span className="action-icon">🛒</span>
            <span className="action-label">Cart</span>
            <span className="cart-count">0</span>
          </button>
        </div>
      </header>

      {/* Navigation */}
      <nav className="dec-nav">
        <a href="#" className="nav-link active">All Sports</a>
        <a href="#" className="nav-link">Fitness &amp; Gym</a>
        <a href="#" className="nav-link">Running</a>
        <a href="#" className="nav-link">Cycling</a>
        <a href="#" className="nav-link">Swimming</a>
        <a href="#" className="nav-link">Team Sports</a>
        <a href="#" className="nav-link">Nutrition</a>
        <a href="#" className="nav-link sale">Sale 🔴</a>
      </nav>

      {/* Hero Banner */}
      <section className="dec-hero">
        <div className="dec-hero-inner">
          <div className="dec-hero-text">
            <p className="hero-tag">YOUR PERSONAL FITNESS TRACKER</p>
            <h1>Track Your <span>Progress.</span><br />Crush Every Goal.</h1>
            <p className="hero-sub">Log your exercises, monitor your body weight, and track your nutrition — all in one place.</p>
            <div className="hero-actions">
              <button className="hero-cta-primary">Start Tracking</button>
              <button className="hero-cta-secondary">Learn More</button>
            </div>
          </div>
          <div className="dec-hero-badges">
            <div className="hero-badge">
              <span className="badge-icon">💪</span>
              <span className="badge-num">500+</span>
              <span className="badge-lbl">Exercises</span>
            </div>
            <div className="hero-badge">
              <span className="badge-icon">🔥</span>
              <span className="badge-num">1M+</span>
              <span className="badge-lbl">Reps Tracked</span>
            </div>
            <div className="hero-badge">
              <span className="badge-icon">🏆</span>
              <span className="badge-num">50K+</span>
              <span className="badge-lbl">Athletes</span>
            </div>
          </div>
        </div>
      </section>

      {/* Sport Category Strip */}
      <section className="sport-strip">
        <div className="sport-strip-inner">
          {SPORTS.map((s) => (
            <div className="sport-chip" key={s.label}>
              <div className="sport-chip-icon">{s.icon}</div>
              <span className="sport-chip-label">{s.label}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Fitness Advisor */}
      <section className="records-section">
        <div className="records-header">
          <div className="records-title-block">
            <h2 className="records-title">My Gym Records</h2>
            <p className="records-sub">Manage your workouts, body weight &amp; nutrition</p>
          </div>
          <span className="records-tag">🏋️ Logged Today</span>
        </div>

        {/* BMI Advisor — apply auto-fills the CREATE form */}
        <FitnessAdvisor onApply={handleAdvisorApply} />

        <Home advisorPick={advisorPick} />
      </section>

    </div>
  );
}

export default App;
