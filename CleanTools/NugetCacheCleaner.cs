namespace CleanTools;

internal class NugetCacheCleaner
{
	public static void Clean(int minDays = 30)
	{
		var nugetCacheFolder = $@"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}\.nuget\packages\";
		var directoryInfo = new DirectoryInfo(nugetCacheFolder);
		long totalDeletedSize = 0;
		foreach (DirectoryInfo folder in directoryInfo.GetDirectories())
		{
			foreach (DirectoryInfo versionFolder in folder.GetDirectories())
			{
				var allFiles = versionFolder.GetFiles("*.*", SearchOption.AllDirectories);

				//selecting only these two as NuGet seem to access .nupkg access sometimes even though they aren't used
				var files = versionFolder.GetFiles("*.metadata", SearchOption.AllDirectories)
					.Concat(versionFolder.GetFiles("*.dll", SearchOption.AllDirectories))
					.ToArray();

				if (files.Length == 0)
					continue;

				DateTime lastAccessTime = files.Max(x => x.LastAccessTime);
				var folderSize = allFiles.Sum(x => x.Length);
				TimeSpan lastAccessed = DateTime.Now - lastAccessTime;

				if (lastAccessed <= TimeSpan.FromDays(minDays))
					continue;

				Console.WriteLine($"{versionFolder.FullName} last accessed {Math.Floor(lastAccessed.TotalDays)} days ago");

				var originalPath = versionFolder.FullName;
				var newPath = Path.Combine(versionFolder.Parent!.FullName, $"_{versionFolder.Name}");

				try
				{
					versionFolder.MoveTo(newPath); //attempt to rename before deleting
					versionFolder.Delete(true);
				}
				finally
				{
					if (versionFolder.Exists && versionFolder.FullName.TrimEnd('\\') == newPath)
						versionFolder.MoveTo(originalPath); //return folder in its original place if removing didn't work
					else
						totalDeletedSize += folderSize;
				}
			}

			if (folder.GetDirectories().Length == 0)
				folder.Delete(true);
		}

		var mbDeleted = (totalDeletedSize / 1024d / 1024d).ToString("0");
		Console.WriteLine($"Done! Deleted {mbDeleted} Mb");
	}
}