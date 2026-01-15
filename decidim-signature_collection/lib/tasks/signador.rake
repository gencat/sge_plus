namespace :signador do
  desc "Enviar un XML al servicio de firma y guardarlo firmado"
  task :sign_xml => :environment do |_t, args|
    xml_content = <<~XML
      <?xml version="1.0" encoding="UTF-8" ?>
      <oce>
        <avalcandidatura>
          <avalista>
            <nomb>Laura</nomb>
            <ape1>Marbella</ape1>
            <ape2>Martorell</ape2>
            <fnac>19941231</fnac>
            <tipoid>1</tipoid>
            <id>00000000T</id>
          </avalista>
        </avalcandidatura>
        <candidatura>
          <elecciones>PARLAMENT DE CATALUNYA</elecciones>
          <circumscripcion>Girona</circumscripcion>
          <nombre>Agrupació d’electors per Girona</nombre>
        </candidatura>
      </oce>
    XML

    puts "📤 Enviando XML para firma..."

    signador = Signador::Client.new
    result = signador.sign_xml(xml_content, id: 1)

    signed_xml = result[1]

    puts "📥 XML firmado recibido"
    puts signed_xml
  end
end
