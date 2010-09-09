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
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyString;

public class Main {
  private static final Properties couplerProperties = new Properties();
  public static final String COUPLER_PROPERTIES = "coupler.properties";
  public static final String JRUBY_PROPERTIES = "jruby.properties";

  static {
    InputStream stream = null;
    try {
      stream = Main.class.getResourceAsStream(COUPLER_PROPERTIES);
      if (stream == null) {
        throw new RuntimeException("Resource not found: " + COUPLER_PROPERTIES);
      }
      couplerProperties.load(stream);
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

  private Main(String[] args) {
    System.out.printf("Coupler version: %s\nBuild date: %s\n\n",
        couplerProperties.getProperty("coupler.version"),
        couplerProperties.getProperty("build.timestamp"));

    // Set JRuby runtime properties
    Properties systemProperties;
    InputStream stream = null;
    try {
      stream = Main.class.getResourceAsStream(JRUBY_PROPERTIES);
      if (stream == null) {
        throw new RuntimeException("Resource not found: " + JRUBY_PROPERTIES);
      }
      systemProperties = new Properties(System.getProperties());
      systemProperties.load(stream);
      System.setProperties(systemProperties);
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

    String location = findCouplerPath();
    List<String> loadPaths = new ArrayList();
    loadPaths.add(location);

    ScriptingContainer container = new ScriptingContainer();
    container.setLoadPaths(loadPaths);

    // FIXME: I feel like there's a simpler way of doing this.
    Ruby ruby = container.getProvider().getRuntime();
    RubyArray rbArray = ruby.newArray();
    for (String string : args) {
      rbArray.append(ruby.newString(string));
    }
    container.put("argv", rbArray);

    // SystemExit gets thrown when someone runs the JAR with --help
    String script =
      "require 'coupler'\n" +
      "begin\n" +
      "  Coupler::Runner.new(argv)\n" +
      "rescue SystemExit\n" +
      "end";
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
    new Main(args);
  }
}
