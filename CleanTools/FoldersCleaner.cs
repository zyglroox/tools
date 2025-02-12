namespace CleanTools;

internal static class FoldersCleaner
{
	private static readonly string[] FoldersToClean =
	[
		$@"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}\AppData\Local\CrashDumps\",
		$@"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}\AppData\Local\Temp\",
		$@"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}\AppData\Roaming\Ableton\Live Reports\",
	];

	public static void Clean()
	{
		foreach (var folder in FoldersToClean)
		{
			CleanFolder(folder);
		}

		void CleanFolder(string folderPath)
		{
			if (!Directory.Exists(folderPath))
			{
				Console.WriteLine($"Skipping: {folderPath} (Not Found)");
				return;
			}

			try
			{
				Console.WriteLine($"Do you want to clean the folder at: {folderPath}? (y/n)");

				// Read the user's response
				var userResponse = Console.ReadLine()?.Trim().ToLower();

				// Check the response
				if (userResponse is not ("y" or "yes"))
					return;

				Console.WriteLine($"Cleaning the folder at: {folderPath}");

				// Delete all files
				foreach (var file in Directory.GetFiles(folderPath))
				{
					File.Delete(file);
				}

				// Delete all subdirectories
				foreach (var dir in Directory.GetDirectories(folderPath))
				{
					Directory.Delete(dir, true);
				}

				Console.WriteLine($"Cleaned: {folderPath}");
			}
			catch (Exception ex)
			{
				Console.WriteLine($"Error cleaning {folderPath}: {ex.Message}");
			}
		}
	}
}