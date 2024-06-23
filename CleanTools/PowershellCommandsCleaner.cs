namespace CleanTools;

internal class PowershellCommandsCleaner
{
	public static async Task Clean()
	{
		const string fileName = "ConsoleHost_history.txt";
		var directoryPath =
			$@"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\";
		var sourceFile = $"{directoryPath}{fileName}";
		var backupFile = $"{directoryPath}Backup_{fileName}";

		var allLines = await File.ReadAllLinesAsync(sourceFile);
		Console.WriteLine($"File contains {allLines.Length} lines");

		File.Copy(sourceFile, backupFile, true);
		Console.WriteLine($"Backup file created: {backupFile}");
		
		var uniqueLines = allLines.ToHashSet();

		var orderedResult = new List<string>();
		foreach (var line in allLines.Reverse())
		{
			if (!uniqueLines.Contains(line))
				continue;

			orderedResult.Add(line);
			uniqueLines.Remove(line);
		}

		orderedResult.Reverse();
		await File.WriteAllLinesAsync(sourceFile, orderedResult);
		Console.WriteLine($"Deleted duplicate lines, {orderedResult.Count} lines left");
	}
}