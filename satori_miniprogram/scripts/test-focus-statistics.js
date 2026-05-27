const assert = require('node:assert/strict')
const { execFileSync } = require('node:child_process')
const fs = require('node:fs')
const path = require('node:path')

const projectRoot = path.resolve(__dirname, '..')
const outDir = path.join(projectRoot, '.test-tmp', 'focus-statistics')
const tscBin = path.join(projectRoot, 'node_modules', 'typescript', 'bin', 'tsc')

fs.rmSync(outDir, { recursive: true, force: true })
fs.mkdirSync(outDir, { recursive: true })

execFileSync(
  process.execPath,
  [
    tscBin,
    '--module', 'CommonJS',
    '--target', 'ES2020',
    '--strict',
    '--skipLibCheck',
    '--typeRoots', path.join(projectRoot, 'typings'),
    '--rootDir', projectRoot,
    '--outDir', outDir,
    path.join(projectRoot, 'miniprogram', 'utils', 'algorithm.ts')
  ],
  { cwd: projectRoot, stdio: 'inherit' }
)

const {
  aggregateFocusRecords,
  buildSevenDayFocusTrend,
  getFocusTrendYAxisLabels,
  getFocusTrendScaleMax
} = require(path.join(outDir, 'miniprogram', 'utils', 'algorithm.js'))

const fixedToday = new Date(2026, 4, 27, 12, 0, 0)
const records = [
  { id: 'r1', taskId: 'task-a', taskName: 'Math', duration: 25, date: '2026-05-27', timestamp: 1 },
  { id: 'r2', taskId: 'task-b', taskName: 'English', duration: 15, date: '2026-05-27', timestamp: 2 },
  { id: 'r3', taskId: 'task-a', taskName: 'Math', duration: 10, date: '2026-05-27', timestamp: 3 },
  { id: 'r4', taskId: 'task-c', taskName: 'Reading', duration: 30, date: '2026-05-26', timestamp: 4 },
  { id: 'r5', taskId: 'task-d', taskName: 'Writing', duration: 20, date: '2026-05-25', timestamp: 5 },
  { id: 'r6', taskId: 'task-e', taskName: 'History', duration: 40, date: '2026-05-19', timestamp: 6 }
]

assert.deepEqual(aggregateFocusRecords(records, fixedToday), {
  todayFocus: 50,
  todayTasks: 2,
  weekFocus: 100,
  weekTasks: 4,
  totalFocus: 140,
  totalTasks: 5
})

assert.deepEqual(
  buildSevenDayFocusTrend(records, fixedToday).map(item => ({
    day: item.day,
    minutes: item.minutes
  })),
  [
    { day: '21', minutes: 0 },
    { day: '22', minutes: 0 },
    { day: '23', minutes: 0 },
    { day: '24', minutes: 0 },
    { day: '25', minutes: 20 },
    { day: '26', minutes: 30 },
    { day: '27', minutes: 50 }
  ]
)

assert.deepEqual(aggregateFocusRecords([], fixedToday), {
  todayFocus: 0,
  todayTasks: 0,
  weekFocus: 0,
  weekTasks: 0,
  totalFocus: 0,
  totalTasks: 0
})

assert.equal(getFocusTrendScaleMax(0), 100)
assert.equal(getFocusTrendScaleMax(130), 200)
assert.deepEqual(getFocusTrendYAxisLabels(130), ['200', '150', '100', '50', '0'])

console.log('focus statistics tests passed')
