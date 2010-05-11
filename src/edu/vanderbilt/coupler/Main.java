package edu.vanderbilt.coupler;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import java.util.ArrayList;
import java.util.List;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.jruby.embed.ScriptingContainer;

public class Main {
  private static final Properties properties = new Properties();
  public static final String PROPFILE = "coupler.properties";
  static {
    InputStream stream = null;
    try {
      stream = Main.class.getResourceAsStream(PROPFILE);
      if (stream == null) {
        throw new RuntimeException("Resource not found: " + PROPFILE);
      }
      properties.load(stream);
    } catch (IOException ioe) {
      ioe.printStackTrace();
    } finally {
      if (stream != null) {
        try {
          stream.close();
        } catch (IOException e) {
          // silently ignore
        }
      }
    }
  }

  private Main() {
    System.out.printf("Coupler version: %s\nBuild date: %s\n\n",
        properties.getProperty("coupler.version"),
        properties.getProperty("build.timestamp"));

    ScriptingContainer container = new ScriptingContainer();
    String location = findCouplerPath();
    List<String> loadPaths = new ArrayList();
    loadPaths.add(location);
    container.getProvider().setLoadPaths(loadPaths);

    String script =
      "require 'coupler'\n" +
      "Coupler::Runner.new";
    container.runScriptlet(script);
  }

  private String findCouplerPath() {
    try {
      URL resource = getClass().getResource("/META-INF/coupler.home/lib/coupler.rb");
      String location = resource.toURI().getSchemeSpecificPart();
      Pattern p = Pattern.compile("coupler\\.rb$");
      Matcher m = p.matcher(location);
      while(m.find()) {
        location = location.substring(0, m.start() - 1);
        return location;
      }
      return null;
    }
    catch (URISyntaxException e) {
      return null;
    }
  }

  public static void main(String[] args) {
    new Main();
  }
}
