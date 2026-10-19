const { test } = require('node:test');
const assert = require('node:assert/strict');
const prune = require('../.github/scripts/prune-releases.cjs');

function release(id, overrides = {}) {
  return {
    id, tag_name: `build-${id}`, draft: false, prerelease: false,
    published_at: `2026-10-${String(id).padStart(2, '0')}T00:00:00Z`,
    ...overrides,
  };
}

function fixture(releases, { snapshots = [], assets } = {}) {
  const deleted = [];
  const calls = [];
  const repos = {
    listReleases: 'releases',
    listReleaseAssets: 'assets',
    deleteRelease: async ({ release_id }) => { deleted.push(release_id); },
  };
  const args = {
    context: { repo: { owner: 'test', repo: 'bridge' } },
    core: { info: () => {} },
    tag: 'build-3',
    github: {
      rest: { repos },
      paginate: async (method, params) => {
        calls.push({ method, params });
        if (method === 'assets') {
          return assets ?? [
            'wearos-bridge-windows.zip',
            'wearos-bridge-macos.tar.gz',
            'wearos-bridge-linux.tar.gz',
          ].map(name => ({ name, state: 'uploaded', size: 1 }));
        }
        return snapshots.shift() ?? releases;
      },
    },
  };
  return { args, deleted, calls };
}

test('keeps newest by publication time, deletes older releases, leaves drafts and prereleases', async () => {
  const f = fixture([
    release(1), release(5, { draft: true }), release(2),
    release(4, { prerelease: true }), release(3),
  ]);
  await prune(f.args);
  assert.deepEqual(f.deleted, [2, 1]);
  assert.ok(f.calls.every(call => call.params.per_page === 100));
});

test('does not prune for an older workflow rerun or a prerelease publication', async () => {
  for (const tag of ['build-2', 'build-4']) {
    const f = fixture([release(2), release(3), release(4, { prerelease: true })]);
    f.args.tag = tag;
    await prune(f.args);
    assert.deepEqual(f.deleted, []);
    assert.equal(f.calls.length, 1);
  }
});

test('refuses pruning when any platform asset is missing, incomplete or empty', async () => {
  for (const change of ['missing', 'incomplete', 'empty']) {
    const assets = [
      { name: 'wearos-bridge-windows.zip', state: 'uploaded', size: 1 },
      { name: 'wearos-bridge-macos.tar.gz', state: 'uploaded', size: 1 },
      { name: 'wearos-bridge-linux.tar.gz', state: 'uploaded', size: 1 },
    ];
    if (change === 'missing') assets.pop();
    if (change === 'incomplete') assets[2].state = 'new';
    if (change === 'empty') assets[2].size = 0;
    const f = fixture([release(3), release(2)], { assets });
    await assert.rejects(prune(f.args), /Retention refused/);
    assert.deepEqual(f.deleted, []);
  }
});

test('stops if another release is published before deletion', async () => {
  const f = fixture([], {
    snapshots: [[release(3), release(2)], [release(4), release(3), release(2)]],
  });
  await prune(f.args);
  assert.deepEqual(f.deleted, []);
});

test('rechecks before each deletion and preserves a release changed to a draft', async () => {
  const f = fixture([], {
    snapshots: [
      [release(3), release(2), release(1)],
      [release(3), release(2), release(1)],
      [release(3), release(1, { draft: true })],
    ],
  });
  await prune(f.args);
  assert.deepEqual(f.deleted, [2]);
  assert.equal(f.calls.filter(call => call.method === 'releases').length, 3);
});

test('surfaces API errors instead of reporting successful pruning', async () => {
  const f = fixture([release(3), release(2)]);
  f.args.github.rest.repos.deleteRelease = async () => { throw new Error('Forbidden'); };
  await assert.rejects(prune(f.args), /Forbidden/);
});
