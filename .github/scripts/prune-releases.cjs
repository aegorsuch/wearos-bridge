const releaseAssets = [
  'wearos-bridge-windows.zip',
  'wearos-bridge-macos.tar.gz',
  'wearos-bridge-linux.tar.gz',
];

function publishedReleases(releases) {
  return releases
    .filter(release => !release.draft && !release.prerelease)
    .sort((a, b) => Date.parse(b.published_at) - Date.parse(a.published_at) || b.id - a.id);
}

module.exports = async function pruneReleases({ github, context, core, tag }) {
  const repo = context.repo;
  const list = async () => publishedReleases(
    await github.paginate(github.rest.repos.listReleases, { ...repo, per_page: 100 }),
  );
  const releases = await list();
  const newest = releases[0];
  if (!newest || newest.tag_name !== tag) {
    core.info('Not the newest published stable release; skipping retention.');
    return;
  }

  const assets = await github.paginate(github.rest.repos.listReleaseAssets, {
    ...repo, release_id: newest.id, per_page: 100,
  });
  for (const name of releaseAssets) {
    if (!assets.some(asset => asset.name === name && asset.state === 'uploaded' && asset.size > 0)) {
      throw new Error(`Retention refused: ${tag} is missing a complete ${name} asset.`);
    }
  }

  for (const older of releases.slice(1)) {
    // Recheck before every deletion so a concurrently published release is preserved.
    const live = await list();
    if (live[0]?.id !== newest.id) {
      core.info('Newest release changed; stopping retention.');
      return;
    }
    if (!live.slice(1).some(release => release.id === older.id)) continue;
    await github.rest.repos.deleteRelease({ ...repo, release_id: older.id });
    core.info(`Deleted release ${older.tag_name}; its git tag is unchanged.`);
  }
};
