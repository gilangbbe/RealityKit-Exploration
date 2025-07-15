# Wave-Based Challenge System

## Overview
The RealityKit Sumo game now features a progressive wave-based challenge system that makes each subsequent wave more difficult and engaging.

## Wave Progression

### Difficulty Scaling
Each wave increases the challenge through multiple parameters:

- **Enemy Count**: +30% more enemies per wave
- **Enemy Speed**: +15% faster movement per wave
- **Spawn Rate**: +10% faster enemy spawning per wave
- **Max Concurrent Enemies**: +25% more enemies on screen
- **Score Multiplier**: +20% more points per enemy defeated

### Visual Progression
Enemies become visually more intimidating as waves progress:
- **Wave 1-2**: Standard red enemies
- **Wave 3-4**: Darker red, slightly metallic
- **Wave 5+**: Dark red/purple, highly metallic and intimidating

### Performance Feedback
The game over screen provides motivational feedback based on wave reached:
- **Wave 1**: "Just getting started!"
- **Waves 2-3**: "Getting the hang of it!"
- **Waves 4-5**: "Impressive survival skills!"
- **Waves 6-8**: "Sumo warrior in training!"
- **Waves 9-12**: "Arena champion!"
- **Wave 13+**: "Legendary sumo master!"

## Technical Implementation

### Core Components
1. **WaveComponent**: Defines individual wave properties
2. **WaveManagerComponent**: Manages wave progression and state
3. **Enhanced SpawnerSystem**: Spawns enemies with wave-based modifiers
4. **Enhanced GameManagementSystem**: Handles wave transitions and scoring

### Configuration
All wave parameters can be adjusted in `GameConfig.swift`:

```swift
// Wave System Configuration
static let baseEnemiesPerWave: Int = 5
static let waveEnemyGrowthRate: Float = 1.3
static let waveSpeedIncrease: Float = 0.15
static let waveHealthIncrease: Float = 0.1
static let waveScoreIncrease: Float = 0.2
static let waveSpawnRateIncrease: Float = 0.1
static let waveMaxEnemiesIncrease: Float = 0.25
```

### Wave Flow
1. **Preparation Phase** (3 seconds): UI shows "PREPARING..." 
2. **Active Phase**: Enemies spawn with wave-based difficulty modifiers
3. **Wave Complete**: All enemies defeated, brief celebration
4. **Next Wave**: Automatic progression after delay

## UI Elements

### Wave HUD
- Current wave number (prominent cyan text)
- Enemy progress bar (orange to red gradient)
- Remaining enemy count
- "PREPARING..." state indicator

### Enhanced Game Over Screen
- Performance-based messaging
- Color-coded wave achievement border
- Wave reached prominently displayed
- Improved visual hierarchy

## Benefits
- **Progressive Challenge**: Keeps players engaged as difficulty scales naturally
- **Clear Feedback**: Players always know their progress and performance level
- **Replayability**: Each attempt to reach higher waves provides motivation
- **Visual Polish**: Enhanced UI and enemy appearance improvements
- **Configurable**: Easy to adjust difficulty curves for balancing
