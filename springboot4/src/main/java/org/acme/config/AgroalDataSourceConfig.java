package org.acme.config;

import java.sql.SQLException;
import java.time.Duration;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.agroal.api.AgroalDataSource;
import io.agroal.api.configuration.AgroalConnectionPoolConfiguration.ConnectionValidator;
import io.agroal.api.configuration.supplier.AgroalDataSourceConfigurationSupplier;
import io.agroal.api.security.NamePrincipal;
import io.agroal.api.security.SimplePassword;

@Configuration
public class AgroalDataSourceConfig {

	@Bean
	public DataSource dataSource(
			@Value("${spring.datasource.url}") String url,
			@Value("${spring.datasource.username}") String username,
			@Value("${spring.datasource.password}") String password) throws SQLException {
		return AgroalDataSource.from(
			new AgroalDataSourceConfigurationSupplier()
				.connectionPoolConfiguration(cp -> cp
					.maxSize(50)
					.minSize(0)
					.acquisitionTimeout(Duration.ofSeconds(5))
					.validationTimeout(Duration.ofMinutes(2))
					.reapTimeout(Duration.ofMinutes(5))
					.connectionValidator(ConnectionValidator.defaultValidator())
					.connectionFactoryConfiguration(cf -> cf
						.jdbcUrl(url)
						.principal(new NamePrincipal(username))
						.credential(new SimplePassword(password))
					)
				)
		);
	}
}
