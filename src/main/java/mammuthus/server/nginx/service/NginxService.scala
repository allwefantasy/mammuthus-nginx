package mammuthus.server.nginx.service

import java.io.FileOutputStream

import com.github.odiszapc.nginxparser.{NgxBlock, NgxConfig, NgxDumper, NgxParam}
import com.google.inject.{Inject, Singleton}
import net.csdn.common.logging.Loggers
import net.csdn.common.settings.Settings

import scala.collection.JavaConversions._
import scala.sys.process._

/**
 * 9/6/15 WilliamZhu(allwefantasy@gmail.com)
 */
@Singleton
class NginxService @Inject()(settings: Settings) {

  val filePath = settings.get("nginx.config.path", "/etc/nginx/upstream")
  val reloadPath = settings.get("nginx.command.path", "/etc/init.d/nginx")
  val logger = Loggers.getLogger(classOf[NginxService])

  /*
   upstream backend {
    server backend1.example.com       weight=5;
    server backend2.example.com:8080;
    server unix:/tmp/backend3;

    server backup1.example.com:8080   backup;
    server backup2.example.com:8080   backup;
    }
   */
  def addServersToUpstream(upstreamName: String, serverList: List[String]) = {
    val (conf, upstream) = findUpStream(upstreamName)
    val serverExits = upstream.asInstanceOf[NgxBlock].getEntries.map(f => f.asInstanceOf[NgxParam].getValue).toSet
    serverList.foreach {
      server =>
        val param = new NgxParam()
        param.addValue("server")
        param.addValue(server)
        if (!serverExits.contains(server)) {
          upstream.asInstanceOf[NgxBlock].addEntry(param)
        }
    }
    dump(conf)
  }

  def findUpStream(upstreamName: String) = {
    val conf = NgxConfig.read(filePath)
    val items = conf.findAll(NgxConfig.BLOCK, "upstream").filter {
      f =>
        f.asInstanceOf[NgxBlock].getValue == upstreamName
    }
    if (items.size != 1) throw new IllegalArgumentException(s"$upstreamName is not exits;please create it first")
    (conf, items(0))
  }

  def removeServersFromUpstream(upstreamName: String, serverList: List[String]) = {
    val (conf, upstream) = findUpStream(upstreamName)
    upstream.asInstanceOf[NgxBlock].getEntries.filter {
      ent =>
        serverList.contains(ent.asInstanceOf[NgxParam].getValue)
    }.foreach {
      f =>
        upstream.asInstanceOf[NgxBlock].getEntries.remove(f)
    }
    dump(conf)
  }

  def dump(conf: NgxConfig) = {
    val dumper = new NgxDumper(conf)
    val file = new FileOutputStream(filePath)
    dumper.dump(file)
    file.close()

    try {
      nginxReload
    } catch {
      case e: Exception =>
        logger.error(e.getMessage, e)
        (-1, e.getMessage, "")
    }
  }

  private def nginxReload = {
    val out = new StringBuilder
    val err = new StringBuilder
    val et = ProcessLogger(
      line => out.append(line + "\n"),
      line => err.append(line + "\n"))
    val pb = Process(reloadPath + " reload")
    val exitValue = pb ! et
    (exitValue, err.toString().trim, out.toString().trim)
  }

}

