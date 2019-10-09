package com.sunrun.movieshow.algorithm.markov;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.log4j.Logger;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

/**
 * Class containing a number of utility methods for manipulating 
 * Hadoop's SequenceFiles.
 *
 *
 * @author Mahmoud Parsian
 *
 */
public class ReadDataFromHDFS {

	private static final Logger THE_LOGGER = 
		Logger.getLogger(ReadDataFromHDFS.class);

	private ReadDataFromHDFS() {
	}
	
	public static List<StateItem> readDirectory(String path) {
		return ReadDataFromHDFS.readDirectory(new Path(path));
	}
	
	public static List<StateItem> readDirectory(Path path) {
		FileSystem fs;
		try {
			fs = FileSystem.get(new Configuration());
		} 
		catch (IOException e) {
			THE_LOGGER.error("Unable to access the hadoop file system!", e);
			throw new RuntimeException("Unable to access the hadoop file system!");
		}
		
		List<StateItem> list = new ArrayList<StateItem>();
		try {
			FileStatus[] stat = fs.listStatus(path);
			for (int i = 0; i < stat.length; ++i) {
				if (stat[i].getPath().getName().startsWith("part")) {
					List<StateItem> pairs = readFile(stat[i].getPath(), fs);
					list.addAll(pairs);
				}
			}
		} 
		catch (IOException e) {
			THE_LOGGER.error("Unable to access the hadoop file system!", e);
			throw new RuntimeException("Error reading the hadoop file system!");
		}

		return list;		
	}	

	@SuppressWarnings("unchecked")
	public static List<StateItem> readFile(Path path, FileSystem fs) {
		THE_LOGGER.info("path="+path);
		List<StateItem> list = new ArrayList<StateItem>();
		FSDataInputStream stream = null;
		BufferedReader reader = null;
		try {
			stream = fs.open(path);
			reader = new BufferedReader(new InputStreamReader(stream));
			String line;
			while ((line = reader.readLine()) != null) {
				// line = <fromState><,><toState><TAB><count>
				THE_LOGGER.info("line="+line);
				String[] tokens = line.split("\t"); // TAB separator
				if (tokens.length == 2) {
					String states = tokens[0];
					int count = Integer.parseInt(tokens[1]);
					String[] twoStates =  states.split(",");
					StateItem item = new StateItem(twoStates[0], twoStates[1], count);
					list.add(item);
				}
			}		
		}
		catch (IOException e) {
			THE_LOGGER.error("readFileIntoCoxRegressionItem() failed!", e);
			throw new RuntimeException("readFileIntoCoxRegressionItem() failed!");
		}
		finally {
			InputOutputUtil.close(reader);
			InputOutputUtil.close(stream);
		}
			
		return list;
	}
	

	
	
	public static void main(String[] args) throws Exception {
		String path = args[0];
		List<StateItem> list = readDirectory(path);
		THE_LOGGER.info("list="+list.toString());
	}
		
}
